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

    @Test func saveRowCounterRetryableFailurePersistsParentProjectPendingForRestart() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveRowCounterError = Self.serverError()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let editedCounter = project.rowCounter.copy(currentRow: 18)

        _ = try await repository.saveRowCounter(editedCounter, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let pendingProject = try #require(await restartedLocal.pendingProjectsForSync().first)
        #expect(pendingProject.id == project.id)
        #expect(pendingProject.syncStatus == .pendingUpload)
        #expect(pendingProject.rowCounter.currentRow == 18)
    }

    @Test func pendingRowCounterRetriesAfterRepositoryRecreationAndClearsPending() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveRowCounterError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let editedCounter = project.rowCounter.copy(currentRow: 24)

        _ = try await repository.saveRowCounter(editedCounter, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.saveRowCounterError = nil

        _ = try await restartedRepository.fetchProjects()

        #expect(remote.savedProjects.map(\.rowCounter.currentRow) == [24])
        #expect(remote.savedRowCounters.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
        #expect(try await restartedLocal.fetchProject(id: project.id)?.rowCounter.syncStatus == .synced)
    }

    @Test func pendingRowInstructionRetriesAfterRepositoryRecreation() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveRowInstructionError = Self.serverError()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let instruction = Self.makeRowInstruction(project: project, rowNumber: 12, syncStatus: .localOnly)

        _ = try await repository.saveRowInstruction(instruction, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.saveRowInstructionError = nil

        _ = try await restartedRepository.fetchProjects()

        #expect(remote.savedProjects.map { $0.rowCounter.rowInstructions.map(\.id) } == [[instruction.id]])
        #expect(remote.savedRowInstructions.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
        #expect(try await restartedLocal.fetchProject(id: project.id)?.rowCounter.rowInstructions.first?.syncStatus == .synced)
    }

    @Test func pendingNewWorkSessionRetriesWithPostAfterRepositoryRecreationWithoutDuplicateCreate() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let recordedProject = project.recordingWorkSession(
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_003_600)
        )
        let session = try #require(recordedProject.workSessions.last)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveWorkSessionError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        _ = try await repository.saveWorkSession(session, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.saveWorkSessionError = nil

        _ = try await restartedRepository.fetchProjects()
        _ = try await restartedRepository.fetchProjects()

        #expect(remote.savedProjects.map { $0.workSessions.map(\.id) } == [[session.id]])
        #expect(remote.savedWorkSessions.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
        #expect(try await restartedLocal.fetchProject(id: project.id)?.workSessions.first?.syncStatus == .synced)
    }

    @Test func successfulImmediateChildRemoteSaveLeavesNoParentPending() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let editedCounter = project.rowCounter.copy(currentRow: 31)

        _ = try await repository.saveRowCounter(editedCounter, forProjectId: project.id)

        #expect(remote.savedRowCounters.map(\.currentRow) == [31])
        #expect(await local.pendingProjectsForSync().isEmpty)
        #expect(try await local.fetchProject(id: project.id)?.syncStatus == .synced)
    }

    @Test func nonRetryableRowCounterFailureRestoresSnapshotAndLeavesNoPending() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.saveRowCounterError = APIError.requestFailed(
            statusCode: 404,
            code: "ROW_COUNTER_NOT_FOUND",
            message: "Row counter not found."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        do {
            _ = try await repository.saveRowCounter(project.rowCounter.copy(currentRow: 99), forProjectId: project.id)
            Issue.record("Expected non-retryable row counter save to throw.")
        } catch let error as APIError {
            #expect(error.statusCode == 404)
        }

        #expect(try await local.fetchProject(id: project.id)?.rowCounter.currentRow == 0)
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    @Test func nonRetryableRowInstructionFailureRestoresSnapshotAndLeavesNoPending() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.saveRowInstructionError = APIError.requestFailed(
            statusCode: 400,
            code: "VALIDATION_ERROR",
            message: "Invalid row instruction."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let instruction = Self.makeRowInstruction(project: project, rowNumber: 12, syncStatus: .localOnly)

        do {
            _ = try await repository.saveRowInstruction(instruction, forProjectId: project.id)
            Issue.record("Expected non-retryable row instruction save to throw.")
        } catch let error as APIError {
            #expect(error.statusCode == 400)
        }

        #expect(try await local.fetchProject(id: project.id)?.rowCounter.rowInstructions.isEmpty == true)
        #expect(await local.pendingProjectsForSync().isEmpty)
    }

    @Test func pendingProjectScalarAndNewRowInstructionRetryUploadsAggregateProject() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let instruction = Self.makeRowInstruction(project: project, rowNumber: 64, syncStatus: .localOnly)
        let updatedProject = project.copy(
            name: "Updated Offline Cardigan",
            rowCounter: project.rowCounter.copy(targetRow: 64, rowInstructions: [instruction]),
            syncStatus: .synced
        )
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.saveProject(updatedProject)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let pendingProject = try #require(await restartedLocal.pendingProjectsForSync().first)
        #expect(pendingProject.name == "Updated Offline Cardigan")
        #expect(pendingProject.syncStatus == .pendingUpload)
        #expect(pendingProject.rowCounter.rowInstructions.map(\.syncStatus) == [.localOnly])

        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.saveProjectError = nil
        remote.updatesRemoteProjectsOnSave = true

        _ = try await restartedRepository.fetchProjects()

        let uploadedProject = try #require(remote.savedProjects.first)
        #expect(uploadedProject.name == "Updated Offline Cardigan")
        #expect(uploadedProject.rowCounter.rowInstructions.map(\.id) == [instruction.id])
        #expect(remote.savedRowInstructions.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)

        let cachedProject = try #require(await restartedLocal.fetchProject(id: project.id))
        #expect(cachedProject.name == "Updated Offline Cardigan")
        #expect(cachedProject.syncStatus == .synced)
        #expect(cachedProject.rowCounter.rowInstructions.map(\.syncStatus) == [.synced])
    }

    @Test func pendingRowCounterScalarAndChildRetryUploadsAggregateProject() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProject(syncStatus: .synced)
        let instruction = Self.makeRowInstruction(project: project, rowNumber: 72, syncStatus: .localOnly)
        let updatedCounter = project.rowCounter.copy(
            currentRow: 18,
            targetRow: 72,
            rowInstructions: [instruction]
        )
        let updatedProject = project.copy(rowCounter: updatedCounter, syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = Self.serverError()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.saveProject(updatedProject)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.saveProjectError = nil
        remote.updatesRemoteProjectsOnSave = true

        _ = try await restartedRepository.fetchProjects()

        let uploadedProject = try #require(remote.savedProjects.first)
        #expect(uploadedProject.rowCounter.currentRow == 18)
        #expect(uploadedProject.rowCounter.targetRow == 72)
        #expect(uploadedProject.rowCounter.rowInstructions.map(\.id) == [instruction.id])
        #expect(remote.savedRowCounters.isEmpty)
        #expect(remote.savedRowInstructions.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
    }

    @Test func pendingAggregateRetryFailureKeepsParentPendingUntilFullUploadSucceeds() async throws {
        let project = Self.makeProject(syncStatus: .synced)
        let instruction = Self.makeRowInstruction(project: project, rowNumber: 88, syncStatus: .localOnly)
        let pendingProject = project.copy(
            rowCounter: project.rowCounter.copy(targetRow: 88, rowInstructions: [instruction]),
            syncStatus: .pendingUpload
        )
        let local = LocalProjectRepository(projects: [pendingProject])
        let remote = ProjectRepositoryFake()
        remote.saveProjectError = Self.serverError()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        _ = try await repository.fetchProjects()

        #expect(remote.savedProjects.isEmpty)
        #expect(remote.savedRowInstructions.isEmpty)
        let stillPending = try #require(await local.pendingProjectsForSync().first)
        #expect(stillPending.syncStatus == .pendingUpload)
        #expect(stillPending.rowCounter.rowInstructions.map(\.syncStatus) == [.localOnly])
    }

    @Test func retryableRowInstructionDeletePersistsPendingAggregateAndDoesNotResurrectAfterRetry() async throws {
        let fileURL = Self.tempProjectFileURL()
        let project = Self.makeProjectWithRowInstruction()
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.remoteProjects = [project]
        remote.updatesRemoteProjectsOnSave = true
        remote.deleteRowInstructionError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let instructionID = try #require(project.rowCounter.rowInstructions.first?.id)

        try await repository.deleteRowInstruction(id: instructionID, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let pendingProject = try #require(await restartedLocal.pendingProjectsForSync().first)
        #expect(pendingProject.syncStatus == .pendingUpload)
        #expect(pendingProject.rowCounter.rowInstructions.isEmpty)

        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.deleteRowInstructionError = nil
        _ = try await restartedRepository.fetchProjects()
        _ = try await restartedRepository.fetchProjects()

        #expect(remote.savedProjects.map { $0.rowCounter.rowInstructions.count } == [0])
        #expect(remote.deletedRowInstructionIDs.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
        #expect(try await restartedLocal.fetchProject(id: project.id)?.rowCounter.rowInstructions.isEmpty == true)
    }

    @Test func retryableWorkSessionDeletePersistsPendingAggregateAndDoesNotResurrectAfterRetry() async throws {
        let fileURL = Self.tempProjectFileURL()
        let session = Self.makeWorkSession(syncStatus: .synced)
        let project = Self.makeProject(syncStatus: .synced).copy(workSessions: [session], syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project], seedSamples: false, fileURL: fileURL)
        let remote = ProjectRepositoryFake()
        remote.remoteProjects = [project]
        remote.updatesRemoteProjectsOnSave = true
        remote.deleteWorkSessionError = Self.serverError()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.deleteWorkSession(id: session.id, forProjectId: project.id)

        let restartedLocal = LocalProjectRepository(seedSamples: false, fileURL: fileURL)
        let pendingProject = try #require(await restartedLocal.pendingProjectsForSync().first)
        #expect(pendingProject.syncStatus == .pendingUpload)
        #expect(pendingProject.workSessions.isEmpty)

        let restartedRepository = OfflineFirstProjectRepository(local: restartedLocal, remote: remote)
        remote.deleteWorkSessionError = nil
        _ = try await restartedRepository.fetchProjects()
        _ = try await restartedRepository.fetchProjects()

        #expect(remote.savedProjects.map { $0.workSessions.count } == [0])
        #expect(remote.deletedWorkSessionIDs.isEmpty)
        #expect(await restartedLocal.pendingProjectsForSync().isEmpty)
        #expect(try await restartedLocal.fetchProject(id: project.id)?.workSessions.isEmpty == true)
    }

    @Test func successfulDirectChildDeleteLeavesNoParentPending() async throws {
        let project = Self.makeProjectWithRowInstruction()
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)
        let instructionID = try #require(project.rowCounter.rowInstructions.first?.id)

        try await repository.deleteRowInstruction(id: instructionID, forProjectId: project.id)

        #expect(remote.deletedRowInstructionIDs == [instructionID])
        #expect(await local.pendingProjectsForSync().isEmpty)
        #expect(try await local.fetchProject(id: project.id)?.rowCounter.rowInstructions.isEmpty == true)
    }

    @Test func alreadyDeletedChildKeepsLocalDeleteWithoutPending() async throws {
        let session = Self.makeWorkSession(syncStatus: .synced)
        let project = Self.makeProject(syncStatus: .synced).copy(workSessions: [session], syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.deleteWorkSessionError = APIError.requestFailed(
            statusCode: 404,
            code: "WORK_SESSION_NOT_FOUND",
            message: "Work session not found."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        try await repository.deleteWorkSession(id: session.id, forProjectId: project.id)

        #expect(await local.pendingProjectsForSync().isEmpty)
        #expect(try await local.fetchProject(id: project.id)?.workSessions.isEmpty == true)
    }

    @Test func nonRetryableChildDeleteRestoresSnapshotAndLeavesNoPending() async throws {
        let session = Self.makeWorkSession(syncStatus: .synced)
        let project = Self.makeProject(syncStatus: .synced).copy(workSessions: [session], syncStatus: .synced)
        let local = LocalProjectRepository(projects: [project])
        let remote = ProjectRepositoryFake()
        remote.deleteWorkSessionError = APIError.requestFailed(
            statusCode: 400,
            code: "VALIDATION_ERROR",
            message: "Invalid work session delete."
        )
        let repository = OfflineFirstProjectRepository(local: local, remote: remote)

        do {
            try await repository.deleteWorkSession(id: session.id, forProjectId: project.id)
            Issue.record("Expected non-retryable work session delete to throw.")
        } catch let error as APIError {
            #expect(error.statusCode == 400)
        }

        #expect(await local.pendingProjectsForSync().isEmpty)
        #expect(try await local.fetchProject(id: project.id)?.workSessions.map(\.id) == [session.id])
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

    private static func makeProjectWithRowInstruction() -> KnittingProject {
        let project = makeProject(syncStatus: .synced)
        let instruction = makeRowInstruction(project: project, rowNumber: 12, syncStatus: .synced)
        return project.copy(
            rowCounter: project.rowCounter.copy(rowInstructions: [instruction]),
            syncStatus: .synced
        )
    }

    private static func makeRowInstruction(
        id: UUID = UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
        project: KnittingProject,
        rowNumber: Int,
        syncStatus: SyncStatus
    ) -> RowInstruction {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return RowInstruction(
            id: id,
            ownerId: project.ownerId,
            projectId: project.id,
            rowCounterId: project.rowCounter.id,
            rowNumber: rowNumber,
            instructionText: "Knit to marker.",
            skillTags: "K",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func makeWorkSession(
        id: UUID = UUID(uuidString: "77777777-7777-4777-8777-777777777777")!,
        syncStatus: SyncStatus
    ) -> WorkSession {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return WorkSession(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            startedAt: now,
            endedAt: now.addingTimeInterval(3_600),
            memo: "Sleeve increases.",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func tempProjectFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("OfflineFirstProjectRepositoryTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("projects.json")
    }

    private static func serverError() -> APIError {
        APIError.requestFailed(
            statusCode: 500,
            code: "SERVER_ERROR",
            message: "Temporary server failure."
        )
    }
}

@MainActor
private final class ProjectRepositoryFake: ProjectRepository {
    var remoteProjects: [KnittingProject] = []
    var savedProjects: [KnittingProject] = []
    var savedRowCounters: [RowCounter] = []
    var savedRowInstructions: [RowInstruction] = []
    var savedRowInstructionMethods: [String] = []
    var savedWorkSessions: [WorkSession] = []
    var savedWorkSessionMethods: [String] = []
    var deletedProjectIDs: [UUID] = []
    var deletedRowInstructionIDs: [UUID] = []
    var deletedWorkSessionIDs: [UUID] = []
    var fetchProjectsError: Error?
    var saveProjectError: Error?
    var saveRowCounterError: Error?
    var saveRowInstructionError: Error?
    var saveWorkSessionError: Error?
    var deleteProjectError: Error?
    var deleteRowInstructionError: Error?
    var deleteWorkSessionError: Error?
    var updatesRemoteProjectsOnSave = false

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
        guard updatesRemoteProjectsOnSave else {
            return
        }

        upsertRemoteProject(Self.syncedAggregate(project))
    }

    func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter {
        if let saveRowCounterError {
            throw saveRowCounterError
        }

        savedRowCounters.append(rowCounter)
        return RowCounter(
            id: rowCounter.id,
            ownerId: rowCounter.ownerId,
            projectId: projectId,
            name: rowCounter.name,
            mode: rowCounter.mode,
            sectionName: rowCounter.sectionName,
            memo: rowCounter.memo,
            currentRow: rowCounter.currentRow,
            targetRow: rowCounter.targetRow,
            rowInstructions: rowCounter.rowInstructions,
            createdAt: rowCounter.createdAt,
            updatedAt: rowCounter.updatedAt,
            deletedAt: rowCounter.deletedAt,
            syncStatus: .synced
        )
    }

    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction {
        if let saveRowInstructionError {
            throw saveRowInstructionError
        }

        savedRowInstructionMethods.append(instruction.syncStatus == .localOnly ? "POST" : "PATCH")
        savedRowInstructions.append(instruction)
        return RowInstruction(
            id: instruction.id,
            ownerId: instruction.ownerId,
            projectId: projectId,
            rowCounterId: instruction.rowCounterId,
            rowNumber: instruction.rowNumber,
            instructionText: instruction.instructionText,
            skillTags: instruction.skillTags,
            createdAt: instruction.createdAt,
            updatedAt: instruction.updatedAt,
            deletedAt: instruction.deletedAt,
            syncStatus: .synced
        )
    }

    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
        if let saveWorkSessionError {
            throw saveWorkSessionError
        }

        savedWorkSessionMethods.append(session.syncStatus == .localOnly ? "POST" : "PATCH")
        savedWorkSessions.append(session)
        return WorkSession(
            id: session.id,
            ownerId: session.ownerId,
            projectId: projectId,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            memo: session.memo,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            deletedAt: session.deletedAt,
            syncStatus: .synced
        )
    }

    func deleteProject(id: UUID) async throws {
        if let deleteProjectError {
            throw deleteProjectError
        }

        deletedProjectIDs.append(id)
    }

    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws {
        if let deleteRowInstructionError {
            throw deleteRowInstructionError
        }

        deletedRowInstructionIDs.append(id)
        guard updatesRemoteProjectsOnSave else {
            return
        }

        remoteProjects = remoteProjects.map { project in
            guard project.id == projectId else {
                return project
            }

            let updatedCounter = project.rowCounter.copy(
                rowInstructions: project.rowCounter.rowInstructions.filter { $0.id != id }
            )
            return project.copy(rowCounter: updatedCounter, syncStatus: .synced)
        }
    }

    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
        if let deleteWorkSessionError {
            throw deleteWorkSessionError
        }

        deletedWorkSessionIDs.append(id)
        guard updatesRemoteProjectsOnSave else {
            return
        }

        remoteProjects = remoteProjects.map { project in
            guard project.id == projectId else {
                return project
            }

            return project.copy(
                workSessions: project.workSessions.filter { $0.id != id },
                syncStatus: .synced
            )
        }
    }

    private func upsertRemoteProject(_ project: KnittingProject) {
        if let index = remoteProjects.firstIndex(where: { $0.id == project.id }) {
            remoteProjects[index] = project
        } else {
            remoteProjects.append(project)
        }
    }

    private static func syncedAggregate(_ project: KnittingProject) -> KnittingProject {
        let syncedInstructions = project.rowCounter.rowInstructions.map { instruction in
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
                syncStatus: .synced
            )
        }
        let syncedCounter = RowCounter(
            id: project.rowCounter.id,
            ownerId: project.rowCounter.ownerId,
            projectId: project.rowCounter.projectId,
            name: project.rowCounter.name,
            mode: project.rowCounter.mode,
            sectionName: project.rowCounter.sectionName,
            memo: project.rowCounter.memo,
            currentRow: project.rowCounter.currentRow,
            targetRow: project.rowCounter.targetRow,
            rowInstructions: syncedInstructions,
            createdAt: project.rowCounter.createdAt,
            updatedAt: project.rowCounter.updatedAt,
            deletedAt: project.rowCounter.deletedAt,
            syncStatus: .synced
        )
        let syncedSessions = project.workSessions.map { session in
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
                syncStatus: .synced
            )
        }

        return project.copy(
            rowCounter: syncedCounter,
            workSessions: syncedSessions,
            syncStatus: .synced
        )
    }
}
