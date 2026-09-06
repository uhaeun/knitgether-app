import Foundation

@MainActor
final class OfflineFirstPatternRepository: PatternRepository {
    private let local: LocalPatternRepository
    private let remote: any PatternRepository

    init(
        local: LocalPatternRepository,
        remote: any PatternRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        await syncPendingChanges()

        do {
            let remotePatterns = try await remote.fetchPatterns()
            try await local.cacheSyncedPatterns(remotePatterns)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchPatterns()
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        await syncPendingChanges()

        do {
            if let remotePattern = try await remote.fetchPattern(id: id) {
                try await local.cacheSyncedPatterns([remotePattern])
            }
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchPattern(id: id)
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localPattern = pattern.copy(
            syncStatus: localSaveSyncStatus(for: pattern.syncStatus)
        )
        try await local.savePattern(localPattern)

        let uploadPattern = pattern.copy(
            syncStatus: uploadSyncStatus(for: pattern.syncStatus)
        )

        do {
            try await remote.savePattern(uploadPattern)
            try await cacheServerPatternIfAvailable(fallback: uploadPattern)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deletePattern(id: UUID) async throws {
        let existingPattern = try await local.fetchPattern(id: id)
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deletePattern(id: id)

        guard existingPattern?.syncStatus != .localOnly else {
            return
        }

        do {
            try await remote.deletePattern(id: id)
            try await local.removePatternTombstone(id: id)
        } catch {
            if shouldTreatDeleteAsSynced(error) {
                try await local.removePatternTombstone(id: id)
                return
            }

            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localPattern = try await local.createPattern(fromFileAt: fileURL)

        do {
            try await remote.savePattern(localPattern)
            try await cacheServerPatternIfAvailable(fallback: localPattern)
            return try await local.fetchPattern(id: localPattern.id) ?? localPattern.copy(syncStatus: .synced)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return localPattern
        }
    }

    func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localPattern = try await local.createPattern(titled: title, designer: designer, notes: notes)

        do {
            try await remote.savePattern(localPattern)
            try await cacheServerPatternIfAvailable(fallback: localPattern)
            return try await local.fetchPattern(id: localPattern.id) ?? localPattern.copy(syncStatus: .synced)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return localPattern
        }
    }

    func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument {
        // 파일 첨부는 오프라인 재시도 동기화 경로가 없어 서버 반영을 먼저 확인한다.
        // 서버 실패 시 로컬을 건드리지 않고 에러를 올려 로컬/서버 불일치를 만들지 않는다.
        let remoteUpdated = try await remote.attachPatternFile(fromFileAt: fileURL, to: pattern)
        let localUpdated = try await local.attachPatternFile(fromFileAt: fileURL, to: pattern)
        try await local.markPatternSynced(remoteUpdated)

        return try await local.fetchPattern(id: pattern.id) ?? localUpdated
    }

    func importPattern(
        _ pattern: PatternDocument,
        forProjectId projectId: UUID
    ) async throws -> ProjectPatternCopy {
        let localPattern = try await local.fetchPattern(id: pattern.id) ?? pattern
        if local.fileURL(for: localPattern) != nil {
            return try await local.importPattern(localPattern, forProjectId: projectId)
        }

        do {
            return try await remote.importPattern(pattern, forProjectId: projectId)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }

            return try await local.importPattern(localPattern, forProjectId: projectId)
        }
    }

    func createProjectPatternCopy(
        fromFileAt fileURL: URL,
        forProjectId projectId: UUID
    ) async throws -> ProjectPatternCopy {
        try await local.createProjectPatternCopy(
            fromFileAt: fileURL,
            forProjectId: projectId
        )
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        local.fileURL(for: pattern) ?? remote.fileURL(for: pattern)
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        local.fileURL(for: patternCopy) ?? remote.fileURL(for: patternCopy)
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        if let data = try await local.drawingData(for: patternCopy) {
            return data
        }

        return try await remote.drawingData(for: patternCopy)
    }

    func saveDrawingData(
        _ data: Data,
        for patternCopy: ProjectPatternCopy
    ) async throws -> ProjectPatternCopy {
        let localCopy = try await local.saveDrawingData(data, for: patternCopy)

        do {
            let remoteCopy = try await remote.saveDrawingData(data, for: patternCopy)
            return remoteCopy.copy(
                localCopyPath: remoteCopy.localCopyPath ?? localCopy.localCopyPath,
                drawingDataPath: localCopy.drawingDataPath,
                drawingUpdatedAt: remoteCopy.drawingUpdatedAt ?? localCopy.drawingUpdatedAt
            )
        } catch {
            guard shouldDefer(error) else {
                throw error
            }

            return localCopy
        }
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        let localCopy = try await local.deleteDrawingData(for: patternCopy)

        do {
            _ = try await remote.deleteDrawingData(for: patternCopy)
            return localCopy
        } catch {
            guard shouldDefer(error) else {
                throw error
            }

            return localCopy
        }
    }

    private func syncPendingChanges() async {
        for pattern in await local.pendingPatternsForSync() {
            do {
                if pattern.syncStatus == .pendingDelete {
                    try await remote.deletePattern(id: pattern.id)
                    try await local.removePatternTombstone(id: pattern.id)
                } else {
                    let uploadPattern = pattern.copy(
                        syncStatus: pattern.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.savePattern(uploadPattern)
                    try await cacheServerPatternIfAvailable(fallback: uploadPattern)
                }
            } catch {
                await resolveRejectedPendingChange(pattern, after: error)
            }
        }
    }

    private func resolveRejectedPendingChange(
        _ pattern: PatternDocument,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch pattern.syncStatus {
        case .localOnly, .pendingDelete:
            try? await local.removePatternTombstone(id: pattern.id)
        case .pendingUpload:
            do {
                if let serverPattern = try await remote.fetchPattern(id: pattern.id) {
                    try await local.markPatternSynced(serverPattern)
                } else {
                    try await local.removePatternTombstone(id: pattern.id)
                }
            } catch {
                if !shouldDefer(error) {
                    try? await local.removePatternTombstone(id: pattern.id)
                }
            }
        default:
            break
        }
    }

    private func cacheServerPatternIfAvailable(fallback pattern: PatternDocument) async throws {
        do {
            if let serverPattern = try await remote.fetchPattern(id: pattern.id) {
                try await local.markPatternSynced(serverPattern)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markPatternSynced(pattern)
    }

    private func shouldDefer(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        if let apiError = error as? APIError,
           let statusCode = apiError.statusCode {
            return statusCode >= 500
        }

        return false
    }

    private func localSaveSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        switch syncStatus {
        case .synced, .pendingUpload:
            return .pendingUpload
        default:
            return .localOnly
        }
    }

    private func uploadSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        syncStatus == .pendingUpload ? .synced : syncStatus
    }

    private func shouldTreatDeleteAsSynced(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.statusCode == 404
        }

        return false
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: [PatternDocument],
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }
}

extension OfflineFirstPatternRepository: OfflineSyncFlushable {
    func flushPendingChanges() async -> Int {
        await syncPendingChanges()
        return await local.pendingPatternsForSync().count
    }
}
