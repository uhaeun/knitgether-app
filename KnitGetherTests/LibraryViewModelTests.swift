import Foundation
import Testing
@testable import KnitGether

@MainActor
struct LibraryViewModelTests {
    @Test func reloadAfterAccountChangeFetchesLibraryAgain() async throws {
        let patternRepository = PatternRepositoryStub(fetchResults: [
            .success([Self.makePattern(title: "Old pattern", ownerId: "user-a")]),
            .success([Self.makePattern(title: "New pattern", ownerId: "user-b")]),
        ])
        let libraryRepository = LibraryRepositoryStub(
            yarnResults: [
                .success([Self.makeYarn(name: "Old yarn", ownerId: "user-a")]),
                .success([Self.makeYarn(name: "New yarn", ownerId: "user-b")]),
            ],
            needleResults: [
                .success([Self.makeNeedle(name: "Old needle", ownerId: "user-a")]),
                .success([Self.makeNeedle(name: "New needle", ownerId: "user-b")]),
            ],
            toolResults: [
                .success([Self.makeTool(name: "Old tool", ownerId: "user-a")]),
                .success([Self.makeTool(name: "New tool", ownerId: "user-b")]),
            ]
        )
        let skillRepository = SkillRepositoryStub(fetchResults: [
            .success([Self.makeSkill(name: "Old skill", ownerId: "user-a")]),
            .success([Self.makeSkill(name: "New skill", ownerId: "user-b")]),
        ])
        let viewModel = LibraryViewModel(
            patternRepository: patternRepository,
            libraryRepository: libraryRepository,
            skillRepository: skillRepository
        )

        await viewModel.loadLibrary()
        await viewModel.reloadAfterAccountChange()

        #expect(patternRepository.fetchCallCount == 2)
        #expect(libraryRepository.fetchYarnCallCount == 2)
        #expect(libraryRepository.fetchNeedleCallCount == 2)
        #expect(libraryRepository.fetchToolCallCount == 2)
        #expect(skillRepository.fetchCallCount == 2)
        #expect(viewModel.patterns.map(\.title) == ["New pattern"])
        #expect(viewModel.yarns.map(\.name) == ["New yarn"])
        #expect(viewModel.needles.map(\.name) == ["New needle"])
        #expect(viewModel.tools.map(\.name) == ["New tool"])
        #expect(viewModel.skills.map(\.name) == ["New skill"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func reloadAfterAccountChangeClearsStaleLibraryWhenFetchFails() async throws {
        let patternRepository = PatternRepositoryStub(fetchResults: [
            .success([Self.makePattern(title: "Private pattern", ownerId: "user-a")]),
            .failure(LibraryRepositoryStubError.fetchFailed),
        ])
        let libraryRepository = LibraryRepositoryStub(
            yarnResults: [
                .success([Self.makeYarn(name: "Private yarn", ownerId: "user-a")]),
            ],
            needleResults: [
                .success([Self.makeNeedle(name: "Private needle", ownerId: "user-a")]),
            ],
            toolResults: [
                .success([Self.makeTool(name: "Private tool", ownerId: "user-a")]),
            ]
        )
        let skillRepository = SkillRepositoryStub(fetchResults: [
            .success([Self.makeSkill(name: "Private skill", ownerId: "user-a")]),
        ])
        let viewModel = LibraryViewModel(
            patternRepository: patternRepository,
            libraryRepository: libraryRepository,
            skillRepository: skillRepository
        )

        await viewModel.loadLibrary()
        await viewModel.reloadAfterAccountChange()

        #expect(viewModel.patterns.isEmpty)
        #expect(viewModel.yarns.isEmpty)
        #expect(viewModel.needles.isEmpty)
        #expect(viewModel.tools.isEmpty)
        #expect(viewModel.skills.isEmpty)
        #expect(viewModel.errorMessage == "Library를 불러오지 못했어요.")
    }

    private static func makePattern(
        title: String,
        ownerId: String
    ) -> PatternDocument {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return PatternDocument(
            ownerId: ownerId,
            title: title,
            designer: nil,
            fileName: nil,
            localFilePath: nil,
            pageCount: nil,
            notes: "",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func makeYarn(
        name: String,
        ownerId: String
    ) -> Yarn {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Yarn(
            id: UUID(),
            ownerId: ownerId,
            name: name,
            brand: nil,
            colorway: nil,
            weight: nil,
            quantity: 1,
            notes: "",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makeNeedle(
        name: String,
        ownerId: String
    ) -> Needle {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Needle(
            id: UUID(),
            ownerId: ownerId,
            name: name,
            needleType: "Circular",
            size: "4.0 mm",
            length: nil,
            notes: "",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makeSkill(
        name: String,
        ownerId: String
    ) -> Skill {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Skill(
            ownerId: ownerId,
            name: name,
            abbreviation: String(name.prefix(1)),
            description: "",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func makeTool(
        name: String,
        ownerId: String
    ) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return ToolItem(
            id: UUID(),
            ownerId: ownerId,
            name: name,
            type: "Marker",
            link: nil,
            memo: "",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }
}

@MainActor
private final class PatternRepositoryStub: PatternRepository {
    private var fetchResults: [Result<[PatternDocument], Error>]
    private(set) var fetchCallCount = 0

    init(fetchResults: [Result<[PatternDocument], Error>]) {
        self.fetchResults = fetchResults
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        fetchCallCount += 1
        return try fetchResults.removeFirst().get()
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        nil
    }

    func savePattern(_ pattern: PatternDocument) async throws {
    }

    func deletePattern(id: UUID) async throws {
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        throw LibraryRepositoryStubError.unsupported
    }

    func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument {
        throw LibraryRepositoryStubError.unsupported
    }

    func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument {
        throw LibraryRepositoryStubError.unsupported
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        throw LibraryRepositoryStubError.unsupported
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        throw LibraryRepositoryStubError.unsupported
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        nil
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        nil
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        nil
    }

    func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        patternCopy
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        patternCopy
    }
}

@MainActor
private final class LibraryRepositoryStub: LibraryRepository {
    private var yarnResults: [Result<[Yarn], Error>]
    private var needleResults: [Result<[Needle], Error>]
    private var toolResults: [Result<[ToolItem], Error>]
    private(set) var fetchYarnCallCount = 0
    private(set) var fetchNeedleCallCount = 0
    private(set) var fetchToolCallCount = 0

    init(
        yarnResults: [Result<[Yarn], Error>],
        needleResults: [Result<[Needle], Error>],
        toolResults: [Result<[ToolItem], Error>] = [.success([])]
    ) {
        self.yarnResults = yarnResults
        self.needleResults = needleResults
        self.toolResults = toolResults
    }

    func fetchYarns() async throws -> [Yarn] {
        fetchYarnCallCount += 1
        return try yarnResults.removeFirst().get()
    }

    func saveYarn(_ yarn: Yarn) async throws {
    }

    func deleteYarn(id: UUID) async throws {
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        []
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        []
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        usage
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        usage
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
    }

    func fetchNeedles() async throws -> [Needle] {
        fetchNeedleCallCount += 1
        return try needleResults.removeFirst().get()
    }

    func saveNeedle(_ needle: Needle) async throws {
    }

    func deleteNeedle(id: UUID) async throws {
    }

    func fetchTools() async throws -> [ToolItem] {
        fetchToolCallCount += 1
        return try toolResults.removeFirst().get()
    }

    func saveTool(_ tool: ToolItem) async throws {
    }

    func deleteTool(id: UUID) async throws {
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        []
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        tool
    }

    func fetchYarnLinks(forProjectId projectId: UUID) async throws -> [ProjectYarnLink] {
        return []
    }

    func linkYarn(_ yarn: Yarn, toProjectId projectId: UUID) async throws -> ProjectYarnLink {
        fatalError("Not needed in this test")
    }

    func unlinkYarn(yarnId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func fetchNeedleLinks(forProjectId projectId: UUID) async throws -> [ProjectNeedleLink] {
        return []
    }

    func linkNeedle(_ needle: Needle, toProjectId projectId: UUID) async throws -> ProjectNeedleLink {
        fatalError("Not needed in this test")
    }

    func unlinkNeedle(needleId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
    }
}

@MainActor
private final class SkillRepositoryStub: SkillRepository {
    private var fetchResults: [Result<[Skill], Error>]
    private(set) var fetchCallCount = 0

    init(fetchResults: [Result<[Skill], Error>]) {
        self.fetchResults = fetchResults
    }

    func fetchSkills() async throws -> [Skill] {
        fetchCallCount += 1
        return try fetchResults.removeFirst().get()
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        nil
    }

    func saveSkill(_ skill: Skill) async throws {
    }

    func deleteSkill(id: UUID) async throws {
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        []
    }
}

private enum LibraryRepositoryStubError: Error {
    case fetchFailed
    case unsupported
}
