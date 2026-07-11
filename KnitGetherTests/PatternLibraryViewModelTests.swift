import Foundation
import Testing
@testable import KnitGether

@MainActor
struct PatternLibraryViewModelTests {
    @Test func formDataInitializesFromExistingPattern() {
        let pattern = Self.pattern(
            title: "Cozy Shawl",
            designer: "Yu",
            pageCount: 12,
            notes: "Use lace markers."
        )

        let formData = PatternFormData(pattern: pattern)

        #expect(formData.title == "Cozy Shawl")
        #expect(formData.designer == "Yu")
        #expect(formData.pageCountText == "12")
        #expect(formData.notes == "Use lace markers.")
    }

    @Test func updatePatternSavesExistingIdentityAndReloadsPatterns() async throws {
        let existing = Self.pattern(
            title: "Old Title",
            designer: "Old Designer",
            fileName: "cozy-shawl.pdf",
            localFilePath: "Patterns/cozy-shawl.pdf",
            pageCount: 8,
            notes: "Old note.",
            syncStatus: .synced
        )
        let repository = FakePatternRepository(patterns: [existing])
        let viewModel = PatternLibraryViewModel(patternRepository: repository)
        let formData = PatternFormData(
            title: "  Cozy Shawl  ",
            designer: "  Yu  ",
            pageCountText: "12",
            notes: "  Use lace markers.  "
        )

        let didSave = await viewModel.updatePattern(existing, from: formData)

        let savedPattern = try #require(repository.savedPattern)
        #expect(didSave)
        #expect(savedPattern.id == existing.id)
        #expect(savedPattern.ownerId == existing.ownerId)
        #expect(savedPattern.title == "Cozy Shawl")
        #expect(savedPattern.designer == "Yu")
        #expect(savedPattern.fileName == existing.fileName)
        #expect(savedPattern.localFilePath == existing.localFilePath)
        #expect(savedPattern.pageCount == 12)
        #expect(savedPattern.notes == "Use lace markers.")
        #expect(savedPattern.createdAt == existing.createdAt)
        #expect(savedPattern.updatedAt > existing.updatedAt)
        #expect(savedPattern.syncStatus == .synced)
        #expect(viewModel.patterns.first?.title == "Cozy Shawl")
    }

    @Test func preparePatternForViewingFetchesMissingFileAndUpdatesList() async throws {
        let listedPattern = Self.pattern(localFilePath: nil)
        let fetchedPattern = Self.pattern(localFilePath: "Patterns/cozy-shawl.pdf")
        let repository = FakePatternRepository(patterns: [listedPattern])
        repository.fetchedPattern = fetchedPattern
        let viewModel = PatternLibraryViewModel(patternRepository: repository)
        await viewModel.loadPatterns()

        let preparedPattern = await viewModel.preparePatternForViewing(listedPattern)

        #expect(repository.fetchedPatternID == listedPattern.id)
        #expect(preparedPattern?.localFilePath == "Patterns/cozy-shawl.pdf")
        #expect(viewModel.patterns.first?.localFilePath == "Patterns/cozy-shawl.pdf")
    }

    @Test func retrySyncReloadsPatternsAndClearsPendingStatus() async throws {
        let pendingPattern = Self.pattern(syncStatus: .pendingUpload)
        let syncedPattern = pendingPattern.copy(syncStatus: .synced)
        let repository = FakePatternRepository(patterns: [pendingPattern])
        repository.fetchResults = [
            [pendingPattern],
            [syncedPattern],
        ]
        let viewModel = PatternLibraryViewModel(patternRepository: repository)

        await viewModel.loadPatterns()
        #expect(viewModel.hasPatternsNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchCallCount == 2)
        #expect(viewModel.patterns.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasPatternsNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func deletePatternDeletesAndReloadsPatterns() async throws {
        let pattern = Self.pattern(title: "Cozy Shawl")
        let repository = FakePatternRepository(patterns: [pattern])
        let viewModel = PatternLibraryViewModel(patternRepository: repository)
        await viewModel.loadPatterns()

        let didDelete = await viewModel.deletePattern(pattern)

        #expect(didDelete)
        #expect(repository.deletedPatternID == pattern.id)
        #expect(viewModel.patterns.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func deletePatternReturnsFalseAndKeepsExistingPatternsWhenDeleteFails() async throws {
        let pattern = Self.pattern(title: "Cozy Shawl")
        let repository = FakePatternRepository(patterns: [pattern])
        repository.shouldFailDeletePattern = true
        let viewModel = PatternLibraryViewModel(patternRepository: repository)
        await viewModel.loadPatterns()

        let didDelete = await viewModel.deletePattern(pattern)

        #expect(!didDelete)
        #expect(viewModel.patterns.map(\.id) == [pattern.id])
        #expect(viewModel.errorMessage == "도안을 삭제하지 못했어요.")
    }

    @Test func patternFileURLUsesRepositoryFileURL() throws {
        let pattern = Self.pattern(localFilePath: "Patterns/cozy-shawl.pdf")
        let repository = FakePatternRepository(patterns: [pattern])
        let fileURL = URL(fileURLWithPath: "/tmp/cozy-shawl.pdf")
        repository.fileURLsByPatternID[pattern.id] = fileURL
        let viewModel = PatternLibraryViewModel(patternRepository: repository)

        #expect(viewModel.fileURL(for: pattern) == fileURL)
    }

    @Test func filteredPatternsMatchesTitleDesignerFileNameAndNotes() async throws {
        let repository = FakePatternRepository(patterns: [
            Self.pattern(
                title: "Cozy Shawl",
                designer: "Yu",
                fileName: "cozy-shawl.pdf",
                notes: "Use lace markers."
            ),
            Self.pattern(
                id: UUID(),
                title: "Summer Tee",
                designer: "Mina",
                fileName: "summer-tee.pdf",
                notes: "Top-down raglan."
            )
        ])
        let viewModel = PatternLibraryViewModel(patternRepository: repository)
        await viewModel.loadPatterns()

        viewModel.searchText = "yu"
        #expect(viewModel.filteredPatterns.map(\.title) == ["Cozy Shawl"])

        viewModel.searchText = "summer-tee"
        #expect(viewModel.filteredPatterns.map(\.title) == ["Summer Tee"])

        viewModel.searchText = "raglan"
        #expect(viewModel.filteredPatterns.map(\.title) == ["Summer Tee"])

        viewModel.searchText = "  "
        #expect(viewModel.filteredPatterns.map(\.title) == ["Cozy Shawl", "Summer Tee"])
    }

    private static func pattern(
        id: UUID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
        title: String = "Cozy Shawl",
        designer: String? = nil,
        fileName: String? = nil,
        localFilePath: String? = nil,
        pageCount: Int? = nil,
        notes: String = "",
        syncStatus: SyncStatus = .localOnly
    ) -> PatternDocument {
        let createdAt = Date(timeIntervalSince1970: 1_783_071_200)
        return PatternDocument(
            id: id,
            ownerId: "user-a",
            title: title,
            designer: designer,
            fileName: fileName,
            localFilePath: localFilePath,
            pageCount: pageCount,
            notes: notes,
            createdAt: createdAt,
            updatedAt: createdAt,
            syncStatus: syncStatus
        )
    }
}

private final class FakePatternRepository: PatternRepository {
    var patterns: [PatternDocument]
    var fetchResults: [[PatternDocument]] = []
    var fetchCallCount = 0
    var savedPattern: PatternDocument?
    var deletedPatternID: UUID?
    var fetchedPatternID: UUID?
    var fetchedPattern: PatternDocument?
    var fileURLsByPatternID: [UUID: URL] = [:]
    var shouldFailDeletePattern = false

    init(patterns: [PatternDocument]) {
        self.patterns = patterns
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        fetchCallCount += 1
        if !fetchResults.isEmpty {
            patterns = fetchResults.removeFirst()
        }
        return patterns
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        fetchedPatternID = id
        return fetchedPattern ?? patterns.first { $0.id == id }
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        savedPattern = pattern

        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }
    }

    func deletePattern(id: UUID) async throws {
        if shouldFailDeletePattern {
            throw URLError(.cannotConnectToHost)
        }

        deletedPatternID = id
        patterns.removeAll { $0.id == id }
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        fatalError("Not needed in this test")
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        fatalError("Not needed in this test")
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        fatalError("Not needed in this test")
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        fileURLsByPatternID[pattern.id]
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        fatalError("Not needed in this test")
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        fatalError("Not needed in this test")
    }

    func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        fatalError("Not needed in this test")
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        fatalError("Not needed in this test")
    }
}
