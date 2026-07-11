import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstProjectRepositoryTests {
    @Test func fetchProjectsFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let localProject = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [localProject])
        let remote = ProjectRepositoryFake()
        remote.fetchProjectsError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        let projects = try await repository.fetchProjects()

        #expect(projects.map(\.id) == [localProject.id])
    }

    @Test func saveNewProjectKeepsLocalChangeAndFlushesOnNextSuccessfulFetch() async throws {
        let local = LocalProjectRepository(projects: [])
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let project = Self.makeProject(syncStatus: .localOnly)

        try await repository.saveProject(project)

        #expect(try await local.fetchProjects().map(\.syncStatus) == [.localOnly])
        #expect(remote.savedProjects.isEmpty)

        remote.saveProjectError = nil
        remote.remoteProjects = [project.copy(syncStatus: .synced)]

        let syncedProjects = try await repository.fetchProjects()

        #expect(remote.savedProjects.map(\.id) == [project.id])
        #expect(remote.savedProjects.map(\.syncStatus) == [.localOnly])
        #expect(syncedProjects.map(\.syncStatus) == [.synced])
    }

    @Test func saveSyncedProjectKeepsPendingUploadAndFlushesAsSyncedOnNextFetch() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let updatedProject = project.copy(name: "Updated Cardigan", syncStatus: .synced)

        try await repository.saveProject(updatedProject)

        #expect(try await local.fetchProjects().map(\.syncStatus) == [.pendingUpload])

        remote.saveProjectError = nil
        remote.remoteProjects = [updatedProject.copy(syncStatus: .synced)]

        _ = try await repository.fetchProjects()

        #expect(remote.savedProjects.map(\.id) == [project.id])
        #expect(remote.savedProjects.map(\.syncStatus) == [.synced])
    }

    @Test func savePendingProjectUploadsAsExistingProjectWhenRemoteIsAvailable() async throws {
        let project = Self.makeProject(syncStatus: .pendingUpload)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.saveProject(project)

        #expect(remote.savedProjects.map(\.id) == [project.id])
        #expect(remote.savedProjects.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchProjects().map(\.syncStatus) == [.synced])
    }

    @Test func saveProjectCachesServerVersionAfterSuccessfulUpload() async throws {
        let project = Self.makeProject(name: "Local Draft", syncStatus: .localOnly)
        let serverProject = Self.makeProject(name: "Server Cardigan", syncStatus: .synced)
        let local = LocalProjectRepository(projects: [])
        let remote = ProjectRepositoryFake()
        remote.remoteProjects = [serverProject]
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.saveProject(project)

        let cachedProject = try #require(await local.fetchProject(id: project.id))
        #expect(cachedProject.name == "Server Cardigan")
        #expect(cachedProject.syncStatus == .synced)
    }

    @Test func deleteProjectKeepsHiddenPendingDeleteAndFlushesOnNextFetch() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.deleteProjectError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.deleteProject(id: project.id)

        #expect(try await local.fetchProjects().isEmpty)
        #expect(await local.pendingProjectsForSync().map(\.syncStatus) == [.pendingDelete])
        #expect(remote.deletedProjectIDs.isEmpty)

        remote.deleteProjectError = nil

        _ = try await repository.fetchProjects()

        #expect(remote.deletedProjectIDs == [project.id])
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    @Test func deleteLocalOnlyProjectDoesNotCallRemoteDelete() async throws {
        let project = Self.makeProject(syncStatus: .localOnly)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.deleteProject(id: project.id)

        #expect(remote.deletedProjectIDs.isEmpty)
        #expect(try await local.fetchProjects().isEmpty)
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    @Test func rejectedPendingLocalOnlyProjectIsRemovedOnFetch() async throws {
        let project = Self.makeProject(syncStatus: .localOnly)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = APIError.requestFailed(
            statusCode: 400,
            code: "VALIDATION_ERROR",
            message: "Invalid project."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        let projects = try await repository.fetchProjects()

        #expect(projects.isEmpty)
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    @Test func rejectedPendingProjectDeleteClearsTombstoneOnFetch() async throws {
        let project = Self.makeProject(syncStatus: .pendingDelete)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.deleteProjectError = APIError.requestFailed(
            statusCode: 404,
            code: "NOT_FOUND",
            message: "Project not found."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        let projects = try await repository.fetchProjects()

        #expect(projects.isEmpty)
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    private static func makeProject(
        id: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        name: String = "Favorite Cardigan",
        syncStatus: SyncStatus
    ) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return KnittingProject(
            id: id,
            ownerId: "user-a",
            name: name,
            status: .wip,
            isFavorite: true,
            memo: "Use smaller needles for ribbing.",
            startDate: now,
            targetDate: nil,
            finishedAt: nil,
            lastWorkedAt: nil,
            patternCopy: nil,
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: id,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now,
                syncStatus: syncStatus
            ),
            workSessions: [],
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }
}

@MainActor
private final class ProjectRepositoryFake: ProjectRepository {
    var remoteProjects: [KnittingProject] = []
    var savedProjects: [KnittingProject] = []
    var deletedProjectIDs: [UUID] = []
    var fetchProjectsError: Error?
    var saveProjectError: Error?
    var deleteProjectError: Error?

    func fetchProjects() async throws -> [KnittingProject] {
        if let fetchProjectsError {
            throw fetchProjectsError
        }

        return remoteProjects
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        if let fetchProjectsError {
            throw fetchProjectsError
        }

        return remoteProjects.first { $0.id == id }
    }

    func saveProject(_ project: KnittingProject) async throws {
        if let saveProjectError {
            throw saveProjectError
        }

        savedProjects.append(project)
    }

    func deleteProject(id: UUID) async throws {
        if let deleteProjectError {
            throw deleteProjectError
        }

        deletedProjectIDs.append(id)
    }
}
