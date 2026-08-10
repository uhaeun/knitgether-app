import Foundation

@MainActor
final class OfflineFirstProjectRepository: ProjectRepository {
    private let local: LocalProjectRepository
    private let remote: any ProjectRepository
    private(set) var isLastListFetchServedFromCache = false

    init(
        local: LocalProjectRepository,
        remote: any ProjectRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchProjects() async throws -> [KnittingProject] {
        await syncPendingChanges()
        var deferredRemoteError: Error?

        do {
            let remoteProjects = try await remote.fetchProjects()
            try await local.cacheSyncedProjects(remoteProjects, pruningStaleEntries: true)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
            deferredRemoteError = error
        }

        let localProjects = try await local.fetchProjects()
        if let deferredRemoteError, localProjects.isEmpty, !local.hasLocalProjectState {
            throw deferredRemoteError
        }

        isLastListFetchServedFromCache = deferredRemoteError != nil
        return localProjects
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        await syncPendingChanges()

        do {
            if let remoteProject = try await remote.fetchProject(id: id) {
                try await local.cacheSyncedProjects([remoteProject])
            }
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchProject(id: id)
    }

    func saveProject(_ project: KnittingProject) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localProject = project.copy(
            syncStatus: localSaveSyncStatus(for: project.syncStatus)
        )
        try await local.saveProject(localProject)

        let uploadProject = project.copy(
            syncStatus: uploadSyncStatus(for: project.syncStatus)
        )

        do {
            try await remote.saveProject(uploadProject)
            try await cacheServerProjectIfAvailable(fallback: uploadProject)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deleteProject(id: UUID) async throws {
        let existingProject = try await local.fetchProject(id: id)
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteProject(id: id)

        guard existingProject?.syncStatus != .localOnly else {
            try await local.removeProjectTombstone(id: id)
            return
        }

        do {
            try await remote.deleteProject(id: id)
            try await local.removeProjectTombstone(id: id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localCounter = copyRowCounter(
            rowCounter,
            syncStatus: localSaveSyncStatus(for: rowCounter.syncStatus)
        )
        let savedCounter = try await local.saveRowCounter(localCounter, forProjectId: projectId)

        let uploadCounter = copyRowCounter(
            rowCounter,
            syncStatus: uploadSyncStatus(for: localCounter.syncStatus)
        )

        do {
            let syncedCounter = try await remote.saveRowCounter(uploadCounter, forProjectId: projectId)
            _ = try await local.saveRowCounter(
                copyRowCounter(syncedCounter, syncStatus: .synced),
                forProjectId: projectId
            )
            return syncedCounter
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            try await markProjectPendingForRetry(projectId: projectId, after: error)
            return savedCounter
        }
    }

    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localInstruction = copyRowInstruction(
            instruction,
            syncStatus: localSaveSyncStatus(for: instruction.syncStatus)
        )
        let savedInstruction = try await local.saveRowInstruction(localInstruction, forProjectId: projectId)

        let uploadInstruction = copyRowInstruction(
            instruction,
            syncStatus: uploadSyncStatus(for: localInstruction.syncStatus)
        )

        do {
            let syncedInstruction = try await remote.saveRowInstruction(uploadInstruction, forProjectId: projectId)
            _ = try await local.saveRowInstruction(
                copyRowInstruction(syncedInstruction, syncStatus: .synced),
                forProjectId: projectId
            )
            return syncedInstruction
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            try await markProjectPendingForRetry(projectId: projectId, after: error)
            return savedInstruction
        }
    }

    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteRowInstruction(id: id, forProjectId: projectId)

        do {
            try await remote.deleteRowInstruction(id: id, forProjectId: projectId)
        } catch {
            try await handleChildDeleteFailure(
                rollbackSnapshot,
                projectId: projectId,
                after: error
            )
        }
    }

    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localSession = copyWorkSession(
            session,
            syncStatus: localSaveSyncStatus(for: session.syncStatus)
        )
        let savedSession = try await local.saveWorkSession(localSession, forProjectId: projectId)

        let uploadSession = copyWorkSession(
            session,
            syncStatus: uploadSyncStatus(for: localSession.syncStatus)
        )

        do {
            let syncedSession = try await remote.saveWorkSession(uploadSession, forProjectId: projectId)
            _ = try await local.saveWorkSession(
                copyWorkSession(syncedSession, syncStatus: .synced),
                forProjectId: projectId
            )
            return syncedSession
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            try await markProjectPendingForRetry(projectId: projectId, after: error)
            return savedSession
        }
    }

    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteWorkSession(id: id, forProjectId: projectId)

        do {
            try await remote.deleteWorkSession(id: id, forProjectId: projectId)
        } catch {
            try await handleChildDeleteFailure(
                rollbackSnapshot,
                projectId: projectId,
                after: error
            )
        }
    }

    private func syncPendingChanges() async {
        for project in await local.pendingProjectsForSync() {
            do {
                if project.syncStatus == .pendingDelete {
                    try await remote.deleteProject(id: project.id)
                    try await local.removeProjectTombstone(id: project.id)
                } else {
                    let uploadProject = project.copy(
                        syncStatus: project.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.saveProject(uploadProject)
                    try await cacheServerProjectIfAvailable(fallback: uploadProject)
                }
            } catch {
                await resolveRejectedPendingChange(project, after: error)
            }
        }
    }

    private func resolveRejectedPendingChange(
        _ project: KnittingProject,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch project.syncStatus {
        case .localOnly:
            // 서버에 존재한 적 없는 유일한 로컬 원본이다. 거부돼도 제거하지 않고
            // 충돌로 표시해 사용자에게 알리고 데이터를 보존한다(SYNC-09).
            try? await local.saveProject(project.copy(syncStatus: .conflict))
        case .pendingUpload:
            // 사용자가 입력한 수정본이다. 서버본으로 무통보 덮어쓰지 않고
            // 충돌로 표시해 로컬 수정을 보존한다(SYNC-10).
            try? await local.saveProject(project.copy(syncStatus: .conflict))
        case .pendingDelete:
            try? await local.removeProjectTombstone(id: project.id)
        default:
            break
        }
    }

    private func cacheServerProjectIfAvailable(fallback project: KnittingProject) async throws {
        do {
            if let serverProject = try await remote.fetchProject(id: project.id) {
                try await local.markProjectSynced(serverProject)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markProjectSynced(syncedAggregate(project))
    }

    private func markProjectPendingForRetry(
        projectId: UUID,
        after error: Error
    ) async throws {
        guard shouldDefer(error),
              let project = try await local.fetchProject(id: projectId) else {
            return
        }

        let syncStatus = pendingRetrySyncStatus(for: project.syncStatus)
        guard syncStatus != project.syncStatus else {
            return
        }

        try await local.saveProject(project.copy(syncStatus: syncStatus))
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

    private func isAlreadyDeleted(_ error: Error) -> Bool {
        guard let apiError = error as? APIError else {
            return false
        }

        return apiError.statusCode == 404
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: [KnittingProject],
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }

    private func handleChildDeleteFailure(
        _ snapshot: [KnittingProject],
        projectId: UUID,
        after error: Error
    ) async throws {
        guard !isAlreadyDeleted(error) else {
            return
        }

        try await rollbackLocalChangeIfRejected(snapshot, after: error)
        try await markProjectPendingForRetry(projectId: projectId, after: error)
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

    private func pendingRetrySyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        switch syncStatus {
        case .synced, .pendingUpload:
            return .pendingUpload
        case .localOnly:
            return .localOnly
        default:
            return syncStatus
        }
    }

    private func syncedAggregate(_ project: KnittingProject) -> KnittingProject {
        let syncedInstructions = project.rowCounter.rowInstructions.map {
            copyRowInstruction($0, syncStatus: .synced)
        }
        let syncedCounter = copyRowCounter(
            project.rowCounter,
            rowInstructions: syncedInstructions,
            syncStatus: .synced
        )
        let syncedSessions = project.workSessions.map {
            copyWorkSession($0, syncStatus: .synced)
        }

        return project.copy(
            rowCounter: syncedCounter,
            workSessions: syncedSessions,
            syncStatus: .synced
        )
    }

    private func copyRowCounter(
        _ rowCounter: RowCounter,
        rowInstructions: [RowInstruction]? = nil,
        syncStatus: SyncStatus
    ) -> RowCounter {
        RowCounter(
            id: rowCounter.id,
            ownerId: rowCounter.ownerId,
            projectId: rowCounter.projectId,
            name: rowCounter.name,
            mode: rowCounter.mode,
            sectionName: rowCounter.sectionName,
            memo: rowCounter.memo,
            currentRow: rowCounter.currentRow,
            targetRow: rowCounter.targetRow,
            rowInstructions: rowInstructions ?? rowCounter.rowInstructions,
            createdAt: rowCounter.createdAt,
            updatedAt: rowCounter.updatedAt,
            deletedAt: rowCounter.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copyRowInstruction(_ instruction: RowInstruction, syncStatus: SyncStatus) -> RowInstruction {
        RowInstruction(
            id: instruction.id,
            ownerId: instruction.ownerId,
            projectId: instruction.projectId,
            rowCounterId: instruction.rowCounterId,
            rowNumber: instruction.rowNumber,
            instructionText: instruction.instructionText,
            skillTags: instruction.skillTags,
            createdAt: instruction.createdAt,
            updatedAt: instruction.updatedAt,
            deletedAt: instruction.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copyWorkSession(_ session: WorkSession, syncStatus: SyncStatus) -> WorkSession {
        WorkSession(
            id: session.id,
            ownerId: session.ownerId,
            projectId: session.projectId,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            memo: session.memo,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            deletedAt: session.deletedAt,
            syncStatus: syncStatus
        )
    }
}
