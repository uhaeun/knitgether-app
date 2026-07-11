import Foundation

@MainActor
final class OfflineFirstDictionaryRepository: DictionaryRepository {
    private let local: LocalDictionaryRepository
    private let remote: any DictionaryRepository

    init(
        local: LocalDictionaryRepository,
        remote: any DictionaryRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchTerms() async throws -> [DictionaryTerm] {
        await syncPendingChanges()

        do {
            let remoteTerms = try await remote.fetchTerms()
            try await local.cacheSyncedTerms(remoteTerms)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchTerms()
    }

    func fetchTerm(id: UUID) async throws -> DictionaryTerm? {
        await syncPendingChanges()

        do {
            if let remoteTerm = try await remote.fetchTerm(id: id) {
                try await local.cacheSyncedTerms([remoteTerm])
            }
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchTerm(id: id)
    }

    func saveTerm(_ term: DictionaryTerm) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localTerm = copyTerm(
            term,
            syncStatus: localSaveSyncStatus(for: term.syncStatus)
        )
        try await local.saveTerm(localTerm)

        let uploadTerm = copyTerm(
            term,
            syncStatus: uploadSyncStatus(for: term.syncStatus)
        )

        do {
            try await remote.saveTerm(uploadTerm)
            try await cacheServerTermIfAvailable(fallback: uploadTerm)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deleteTerm(id: UUID) async throws {
        let existingTerm = try await local.fetchTerm(id: id)
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteTerm(id: id)

        guard existingTerm?.syncStatus != .localOnly else {
            try await local.removeTermTombstone(id: id)
            return
        }

        do {
            try await remote.deleteTerm(id: id)
            try await local.removeTermTombstone(id: id)
        } catch {
            if shouldTreatDeleteAsSynced(error) {
                try await local.removeTermTombstone(id: id)
                return
            }

            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    private func syncPendingChanges() async {
        for term in await local.pendingTermsForSync() {
            do {
                if term.syncStatus == .pendingDelete {
                    try await remote.deleteTerm(id: term.id)
                    try await local.removeTermTombstone(id: term.id)
                } else {
                    let uploadTerm = copyTerm(
                        term,
                        syncStatus: term.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.saveTerm(uploadTerm)
                    try await cacheServerTermIfAvailable(fallback: uploadTerm)
                }
            } catch {
                await resolveRejectedPendingChange(term, after: error)
            }
        }
    }

    private func resolveRejectedPendingChange(
        _ term: DictionaryTerm,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch term.syncStatus {
        case .localOnly, .pendingDelete:
            try? await local.removeTermTombstone(id: term.id)
        case .pendingUpload:
            do {
                if let serverTerm = try await remote.fetchTerm(id: term.id) {
                    try await local.markTermSynced(serverTerm)
                } else {
                    try await local.removeTermTombstone(id: term.id)
                }
            } catch {
                if !shouldDefer(error) {
                    try? await local.removeTermTombstone(id: term.id)
                }
            }
        default:
            break
        }
    }

    private func cacheServerTermIfAvailable(fallback term: DictionaryTerm) async throws {
        do {
            if let serverTerm = try await remote.fetchTerm(id: term.id) {
                try await local.markTermSynced(serverTerm)
                return
            }
        } catch {
        }

        try await local.markTermSynced(term)
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

    private func shouldTreatDeleteAsSynced(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.statusCode == 404
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

    private func copyTerm(
        _ term: DictionaryTerm,
        syncStatus: SyncStatus
    ) -> DictionaryTerm {
        term.copy(syncStatus: syncStatus)
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: [DictionaryTerm],
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }
}
