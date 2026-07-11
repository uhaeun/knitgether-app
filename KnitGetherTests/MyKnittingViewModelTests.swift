import Foundation
import Testing
@testable import KnitGether

@MainActor
struct MyKnittingViewModelTests {
    @Test func addProjectSavesSelectedYarnAndNeedleSnapshots() async throws {
        let repository = ProjectRepositoryStub(fetchResults: [
            .success([]),
            .success([]),
        ])
        let viewModel = MyKnittingViewModel(projectRepository: repository)
        let yarn = Self.makeYarn()
        let needle = Self.makeNeedle()
        var formData = ProjectFormData(name: "Material Project")
        formData.selectYarn(yarn)
        formData.selectNeedle(needle)

        await viewModel.addProject(from: formData)

        let savedProject = try #require(repository.savedProjects.first)
        #expect(savedProject.yarnId == yarn.id)
        #expect(savedProject.yarnNameSnapshot == "Soft Merino DK")
        #expect(savedProject.yarnBrandSnapshot == "Sample Yarn Co.")
        #expect(savedProject.yarnColorwaySnapshot == "Cloud Gray")
        #expect(savedProject.yarnWeightSnapshot == "DK")
        #expect(savedProject.needleId == needle.id)
        #expect(savedProject.needleNameSnapshot == "Wood Circular Needle")
        #expect(savedProject.needleTypeSnapshot == "Circular")
        #expect(savedProject.needleSizeSnapshot == "5.0 mm")
        #expect(savedProject.needleLengthSnapshot == "80 cm")
    }

    @Test func addProjectReturnsFalseAndKeepsErrorWhenSaveFails() async throws {
        let repository = ProjectRepositoryStub(fetchResults: [.success([])])
        repository.shouldFailSave = true
        let viewModel = MyKnittingViewModel(projectRepository: repository)

        let didSave = await viewModel.addProject(from: ProjectFormData(name: "Failing Project"))

        #expect(!didSave)
        #expect(repository.savedProjects.isEmpty)
        #expect(viewModel.errorMessage == "프로젝트를 추가하지 못했어요.")
    }

    @Test func updateProjectReturnsFalseAndKeepsExistingListWhenSaveFails() async throws {
        let project = Self.makeProject(name: "Existing", ownerId: "user-a")
        let repository = ProjectRepositoryStub(fetchResults: [.success([project])])
        repository.shouldFailSave = true
        let viewModel = MyKnittingViewModel(projectRepository: repository)
        await viewModel.loadProjects()

        let didSave = await viewModel.updateProject(
            project,
            with: ProjectFormData(project: project)
        )

        #expect(!didSave)
        #expect(viewModel.projects.map(\.name) == ["Existing"])
        #expect(viewModel.errorMessage == "프로젝트를 수정하지 못했어요.")
    }

    @Test func deleteProjectReturnsFalseAndKeepsExistingListWhenDeleteFails() async throws {
        let project = Self.makeProject(name: "Existing", ownerId: "user-a")
        let repository = ProjectRepositoryStub(fetchResults: [.success([project])])
        repository.shouldFailDelete = true
        let viewModel = MyKnittingViewModel(projectRepository: repository)
        await viewModel.loadProjects()

        let didDelete = await viewModel.deleteProject(project)

        #expect(!didDelete)
        #expect(viewModel.projects.map(\.name) == ["Existing"])
        #expect(viewModel.errorMessage == "프로젝트를 삭제하지 못했어요.")
    }

    @Test func addProjectSavesSelectedPatternDocumentAsProjectPatternCopy() async throws {
        let repository = ProjectRepositoryStub(fetchResults: [
            .success([]),
            .success([]),
        ])
        let viewModel = MyKnittingViewModel(projectRepository: repository)
        let pattern = Self.makePattern()
        var formData = ProjectFormData(name: "Pattern Project")
        formData.selectPattern(pattern)

        await viewModel.addProject(from: formData)

        let savedProject = try #require(repository.savedProjects.first)
        let patternCopy = try #require(savedProject.patternCopy)
        #expect(patternCopy.projectId == savedProject.id)
        #expect(patternCopy.sourcePatternDocumentId == pattern.id)
        #expect(patternCopy.titleSnapshot == "Cozy Shawl")
        #expect(patternCopy.designerSnapshot == "Yuha")
        #expect(patternCopy.fileNameSnapshot == "cozy-shawl.pdf")
        #expect(patternCopy.pageCountSnapshot == 12)
    }

    @Test func manualPatternNameClearsPreviouslySelectedPatternDocument() {
        var formData = ProjectFormData(name: "Pattern Project")
        formData.selectPattern(Self.makePattern())

        formData.setManualPatternName("My handwritten notes")

        #expect(formData.patternDocumentId == nil)
        #expect(formData.patternName == "My handwritten notes")
        #expect(formData.patternDesignerSnapshot == "")
        #expect(formData.patternFileNameSnapshot == "")
        #expect(formData.patternPageCountSnapshot == nil)
    }

    @Test func projectFormDataInitializesMaterialSelectionFromProject() {
        let yarnID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
        let needleID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!
        let project = Self.makeProject(
            name: "Material Project",
            ownerId: "user-a",
            yarnId: yarnID,
            yarnNameSnapshot: "Soft Merino DK",
            yarnBrandSnapshot: "Sample Yarn Co.",
            yarnColorwaySnapshot: "Cloud Gray",
            yarnWeightSnapshot: "DK",
            needleId: needleID,
            needleNameSnapshot: "Wood Circular Needle",
            needleTypeSnapshot: "Circular",
            needleSizeSnapshot: "5.0 mm",
            needleLengthSnapshot: "80 cm"
        )

        let formData = ProjectFormData(project: project)

        #expect(formData.yarnId == yarnID)
        #expect(formData.yarnNameSnapshot == "Soft Merino DK")
        #expect(formData.yarnSummaryText == "Soft Merino DK · Sample Yarn Co. · Cloud Gray · DK")
        #expect(formData.needleId == needleID)
        #expect(formData.needleNameSnapshot == "Wood Circular Needle")
        #expect(formData.needleSummaryText == "Wood Circular Needle · Circular · 5.0 mm · 80 cm")
    }

    @Test func reloadAfterAccountChangeFetchesProjectsAgain() async throws {
        let repository = ProjectRepositoryStub(fetchResults: [
            .success([Self.makeProject(name: "Old account project", ownerId: "user-a")]),
            .success([Self.makeProject(name: "New account project", ownerId: "user-b")]),
        ])
        let viewModel = MyKnittingViewModel(projectRepository: repository)

        await viewModel.loadProjects()
        await viewModel.reloadAfterAccountChange()

        #expect(repository.fetchCallCount == 2)
        #expect(viewModel.projects.map(\.name) == ["New account project"])
        #expect(viewModel.projects.first?.ownerId == "user-b")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func reloadAfterAccountChangeClearsStaleProjectsWhenFetchFails() async throws {
        let repository = ProjectRepositoryStub(fetchResults: [
            .success([Self.makeProject(name: "Private project", ownerId: "user-a")]),
            .failure(ProjectRepositoryStubError.fetchFailed),
        ])
        let viewModel = MyKnittingViewModel(projectRepository: repository)

        await viewModel.loadProjects()
        await viewModel.reloadAfterAccountChange()

        #expect(repository.fetchCallCount == 2)
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.errorMessage == "프로젝트를 불러오지 못했어요.")
    }

    @Test func retrySyncReloadsProjectsAndClearsPendingStatus() async throws {
        let pendingProject = Self.makeProject(
            name: "Offline cardigan",
            ownerId: "user-a",
            syncStatus: .pendingUpload
        )
        let syncedProject = pendingProject.copy(syncStatus: .synced)
        let repository = ProjectRepositoryStub(fetchResults: [
            .success([pendingProject]),
            .success([syncedProject]),
        ])
        let viewModel = MyKnittingViewModel(projectRepository: repository)

        await viewModel.loadProjects()
        #expect(viewModel.hasProjectsNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchCallCount == 2)
        #expect(viewModel.projects.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasProjectsNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    private static func makeProject(
        name: String,
        ownerId: String,
        yarnId: UUID? = nil,
        yarnNameSnapshot: String? = nil,
        yarnBrandSnapshot: String? = nil,
        yarnColorwaySnapshot: String? = nil,
        yarnWeightSnapshot: String? = nil,
        needleId: UUID? = nil,
        needleNameSnapshot: String? = nil,
        needleTypeSnapshot: String? = nil,
        needleSizeSnapshot: String? = nil,
        needleLengthSnapshot: String? = nil,
        syncStatus: SyncStatus = .synced
    ) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        let projectId = UUID()

        return KnittingProject(
            id: projectId,
            ownerId: ownerId,
            name: name,
            status: .wip,
            isFavorite: false,
            memo: "",
            startDate: now,
            lastWorkedAt: nil,
            patternCopy: nil,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            yarnBrandSnapshot: yarnBrandSnapshot,
            yarnColorwaySnapshot: yarnColorwaySnapshot,
            yarnWeightSnapshot: yarnWeightSnapshot,
            needleId: needleId,
            needleNameSnapshot: needleNameSnapshot,
            needleTypeSnapshot: needleTypeSnapshot,
            needleSizeSnapshot: needleSizeSnapshot,
            needleLengthSnapshot: needleLengthSnapshot,
            rowCounter: RowCounter(
                ownerId: ownerId,
                projectId: projectId,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now
            ),
            workSessions: [],
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func makeYarn() -> Yarn {
        Yarn(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            ownerId: "user-a",
            name: "Soft Merino DK",
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: 5,
            notes: "",
            createdAt: Date(timeIntervalSince1970: 1_783_735_200),
            updatedAt: Date(timeIntervalSince1970: 1_783_735_200),
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makeNeedle() -> Needle {
        Needle(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            ownerId: "user-a",
            name: "Wood Circular Needle",
            needleType: "Circular",
            size: "5.0 mm",
            length: "80 cm",
            notes: "",
            createdAt: Date(timeIntervalSince1970: 1_783_735_200),
            updatedAt: Date(timeIntervalSince1970: 1_783_735_200),
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makePattern() -> PatternDocument {
        PatternDocument(
            id: UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
            ownerId: "user-a",
            title: "Cozy Shawl",
            designer: "Yuha",
            fileName: "cozy-shawl.pdf",
            localFilePath: "Patterns/cozy-shawl.pdf",
            pageCount: 12,
            notes: "",
            createdAt: Date(timeIntervalSince1970: 1_783_735_200),
            updatedAt: Date(timeIntervalSince1970: 1_783_735_200),
            deletedAt: nil,
            syncStatus: .synced
        )
    }
}

@MainActor
private final class ProjectRepositoryStub: ProjectRepository {
    private var fetchResults: [Result<[KnittingProject], Error>]
    private(set) var fetchCallCount = 0
    private(set) var savedProjects: [KnittingProject] = []
    var shouldFailSave = false
    var shouldFailDelete = false

    init(fetchResults: [Result<[KnittingProject], Error>]) {
        self.fetchResults = fetchResults
    }

    func fetchProjects() async throws -> [KnittingProject] {
        fetchCallCount += 1

        guard !fetchResults.isEmpty else {
            return []
        }

        return try fetchResults.removeFirst().get()
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        nil
    }

    func saveProject(_ project: KnittingProject) async throws {
        if shouldFailSave {
            throw ProjectRepositoryStubError.saveFailed
        }

        savedProjects.append(project)
    }

    func deleteProject(id: UUID) async throws {
        if shouldFailDelete {
            throw ProjectRepositoryStubError.deleteFailed
        }
    }
}

private enum ProjectRepositoryStubError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
}
