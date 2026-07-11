import Foundation

@MainActor
final class OfflineFirstProjectRepository: ProjectRepository {
    private let local: LocalProjectRepository
    private let remote: any ProjectRepository

    init(
        local: LocalProjectRepository,
        remote: any ProjectRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchProjects() async throws -> [KnittingProject] {
        await syncPendingChanges()

        do {
            let remoteProjects = try await remote.fetchProjects()
            try await local.cacheSyncedProjects(remoteProjects)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchProjects()
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
        let savedCounter = try await local.saveRowCounter(rowCounter, forProjectId: projectId)

        do {
            let syncedCounter = try await remote.saveRowCounter(rowCounter, forProjectId: projectId)
            _ = try await local.saveRowCounter(syncedCounter, forProjectId: projectId)
            return syncedCounter
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            return savedCounter
        }
    }

    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let savedInstruction = try await local.saveRowInstruction(instruction, forProjectId: projectId)

        do {
            let syncedInstruction = try await remote.saveRowInstruction(instruction, forProjectId: projectId)
            _ = try await local.saveRowInstruction(syncedInstruction, forProjectId: projectId)
            return syncedInstruction
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            return savedInstruction
        }
    }

    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteRowInstruction(id: id, forProjectId: projectId)

        do {
            try await remote.deleteRowInstruction(id: id, forProjectId: projectId)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let savedSession = try await local.saveWorkSession(session, forProjectId: projectId)

        do {
            let syncedSession = try await remote.saveWorkSession(session, forProjectId: projectId)
            _ = try await local.saveWorkSession(syncedSession, forProjectId: projectId)
            return syncedSession
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            return savedSession
        }
    }

    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteWorkSession(id: id, forProjectId: projectId)

        do {
            try await remote.deleteWorkSession(id: id, forProjectId: projectId)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
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
        case .localOnly, .pendingDelete:
            try? await local.removeProjectTombstone(id: project.id)
        case .pendingUpload:
            do {
                if let serverProject = try await remote.fetchProject(id: project.id) {
                    try await local.markProjectSynced(serverProject)
                } else {
                    try await local.removeProjectTombstone(id: project.id)
                }
            } catch {
                if !shouldDefer(error) {
                    try? await local.removeProjectTombstone(id: project.id)
                }
            }
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

        try await local.markProjectSynced(project)
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
}
