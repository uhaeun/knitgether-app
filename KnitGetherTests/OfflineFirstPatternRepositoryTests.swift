import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstPatternRepositoryTests {
    @Test func fetchPatternsFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let localPattern = try Self.makeStoredPattern(
            in: tempDirectory,
            fileName: "local-shawl.pdf",
            syncStatus: .synced
        )
        let local = Self.makeLocalRepository(
            patterns: [localPattern],
            tempDirectory: tempDirectory
        )
        let remote = PatternRepositoryFake()
        remote.fetchPatternsError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        let patterns = try await repository.fetchPatterns()

        #expect(patterns.map(\.id) == [localPattern.id])
    }

    @Test func createPatternKeepsLocalFileAndFlushesUploadOnNextFetch() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sourceURL = tempDirectory.appendingPathComponent("new-pattern.pdf")
        try Data("%PDF-1.4 offline".utf8).write(to: sourceURL)
        let local = Self.makeLocalRepository(patterns: [], tempDirectory: tempDirectory)
        let remote = PatternRepositoryFake()
        remote.savePatternError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        let createdPattern = try await repository.createPattern(fromFileAt: sourceURL)

        #expect(createdPattern.syncStatus == .localOnly)
        #expect(remote.savedPatterns.isEmpty)
        let localURL = try #require(local.fileURL(for: createdPattern))
        #expect(FileManager.default.fileExists(atPath: localURL.path))

        remote.savePatternError = nil
        remote.remotePatterns = [createdPattern.copy(syncStatus: .synced)]

        let syncedPatterns = try await repository.fetchPatterns()

        #expect(remote.savedPatterns.map(\.id) == [createdPattern.id])
        #expect(remote.savedPatterns.map(\.syncStatus) == [.localOnly])
        #expect(syncedPatterns.map(\.syncStatus) == [.synced])
        let syncedURL = try #require(local.fileURL(for: syncedPatterns[0]))
        #expect(FileManager.default.fileExists(atPath: syncedURL.path))
    }

    @Test func savePendingPatternUploadsAsExistingPatternWhenRemoteIsAvailable() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let pattern = try Self.makeStoredPattern(
            in: tempDirectory,
            fileName: "pending-cardigan.pdf",
            syncStatus: .pendingUpload
        )
        let local = Self.makeLocalRepository(
            patterns: [pattern],
            tempDirectory: tempDirectory
        )
        let remote = PatternRepositoryFake()
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        try await repository.savePattern(pattern)

        #expect(remote.savedPatterns.map(\.id) == [pattern.id])
        #expect(remote.savedPatterns.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchPatterns().map(\.syncStatus) == [.synced])
    }

    @Test func savePatternCachesServerVersionAndKeepsLocalFileAfterSuccessfulUpload() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let pattern = try Self.makeStoredPattern(
            in: tempDirectory,
            fileName: "local-cardigan.pdf",
            syncStatus: .localOnly
        )
        let serverPattern = pattern.copy(title: "Server Cardigan", syncStatus: .synced)
        let local = Self.makeLocalRepository(
            patterns: [],
            tempDirectory: tempDirectory
        )
        let remote = PatternRepositoryFake()
        remote.remotePatterns = [serverPattern]
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        try await repository.savePattern(pattern)

        let cachedPattern = try #require(await local.fetchPattern(id: pattern.id))
        let cachedFileURL = try #require(local.fileURL(for: cachedPattern))
        #expect(cachedPattern.title == "Server Cardigan")
        #expect(cachedPattern.syncStatus == .synced)
        #expect(FileManager.default.fileExists(atPath: cachedFileURL.path))
    }

    @Test func deletePatternKeepsHiddenPendingDeleteAndFlushesOnNextFetch() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let localPattern = try Self.makeStoredPattern(
            in: tempDirectory,
            fileName: "deleted-shawl.pdf",
            syncStatus: .synced
        )
        let local = Self.makeLocalRepository(
            patterns: [localPattern],
            tempDirectory: tempDirectory
        )
        let remote = PatternRepositoryFake()
        remote.deletePatternError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        try await repository.deletePattern(id: localPattern.id)

        #expect(try await local.fetchPatterns().isEmpty)
        #expect(await local.pendingPatternsForSync().map(\.syncStatus) == [.pendingDelete])
        #expect(remote.deletedPatternIDs.isEmpty)
        let preservedURL = try #require(local.fileURL(for: localPattern))
        #expect(FileManager.default.fileExists(atPath: preservedURL.path))

        remote.deletePatternError = nil

        _ = try await repository.fetchPatterns()

        #expect(remote.deletedPatternIDs == [localPattern.id])
        #expect(await local.pendingPatternsForSync().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: preservedURL.path))
    }

    @Test func deleteLocalOnlyPatternDoesNotCallRemoteDelete() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let localPattern = try Self.makeStoredPattern(
            in: tempDirectory,
            fileName: "local-only-shawl.pdf",
            syncStatus: .localOnly
        )
        let local = Self.makeLocalRepository(
            patterns: [localPattern],
            tempDirectory: tempDirectory
        )
        let remote = PatternRepositoryFake()
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)

        try await repository.deletePattern(id: localPattern.id)

        #expect(remote.deletedPatternIDs.isEmpty)
        #expect(try await local.fetchPatterns().isEmpty)
        #expect(await local.pendingPatternsForSync().isEmpty)
    }

    @Test func createProjectPatternCopyKeepsDirectFileLocalForProjectUpload() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sourceURL = tempDirectory.appendingPathComponent("direct-cardigan.pdf")
        try Data("%PDF-1.4 direct".utf8).write(to: sourceURL)
        let local = Self.makeLocalRepository(patterns: [], tempDirectory: tempDirectory)
        let remote = PatternRepositoryFake()
        let repository = OfflineFirstPatternRepository(local: local, remote: remote)
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

        let patternCopy = try await repository.createProjectPatternCopy(
            fromFileAt: sourceURL,
            forProjectId: projectID
        )

        #expect(patternCopy.sourcePatternDocumentId == nil)
        #expect(remote.createdProjectPatternCopyUploads.isEmpty)
        let localURL = try #require(local.fileURL(for: patternCopy))
        #expect(FileManager.default.fileExists(atPath: localURL.path))
    }

    private static func makeStoredPattern(
        in tempDirectory: URL,
        fileName: String,
        syncStatus: SyncStatus
    ) throws -> PatternDocument {
        let patternID = UUID()
        let sourceURL = tempDirectory.appendingPathComponent(fileName)
        try Data("%PDF-1.4".utf8).write(to: sourceURL)
        let fileStore = LocalPatternFileStore(
            rootDirectoryURL: tempDirectory.appendingPathComponent("files", isDirectory: true)
        )
        let storedFile = try fileStore.storeLibraryPatternFile(
            from: sourceURL,
            patternId: patternID
        )
        let now = Date(timeIntervalSince1970: 1_783_735_200)

        return PatternDocument(
            id: patternID,
            ownerId: "user-a",
            title: fileName.replacingOccurrences(of: ".pdf", with: ""),
            designer: "Yu",
            fileName: storedFile.fileName,
            localFilePath: storedFile.relativePath,
            pageCount: 12,
            notes: "Test pattern",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func makeLocalRepository(
        patterns: [PatternDocument],
        tempDirectory: URL
    ) -> LocalPatternRepository {
        LocalPatternRepository(
            patterns: patterns,
            fileURL: tempDirectory.appendingPathComponent("patterns.json"),
            fileStore: LocalPatternFileStore(
                rootDirectoryURL: tempDirectory.appendingPathComponent("files", isDirectory: true)
            )
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OfflineFirstPatternRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

@MainActor
private final class PatternRepositoryFake: PatternRepository {
    var remotePatterns: [PatternDocument] = []
    var savedPatterns: [PatternDocument] = []
    var deletedPatternIDs: [UUID] = []
    var createdProjectPatternCopyUploads: [URL] = []
    var fetchPatternsError: Error?
    var savePatternError: Error?
    var deletePatternError: Error?

    func fetchPatterns() async throws -> [PatternDocument] {
        if let fetchPatternsError {
            throw fetchPatternsError
        }

        return remotePatterns
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        if let fetchPatternsError {
            throw fetchPatternsError
        }

        return remotePatterns.first { $0.id == id }
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        if let savePatternError {
            throw savePatternError
        }

        savedPatterns.append(pattern)
    }

    func deletePattern(id: UUID) async throws {
        if let deletePatternError {
            throw deletePatternError
        }

        deletedPatternIDs.append(id)
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        let pattern = PatternDocument(
            ownerId: "user-a",
            title: fileURL.deletingPathExtension().lastPathComponent,
            designer: nil,
            fileName: fileURL.lastPathComponent,
            localFilePath: nil,
            pageCount: nil,
            notes: "",
            createdAt: now,
            updatedAt: now
        )
        try await savePattern(pattern)
        return pattern
    }

    func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument {
        fatalError("Not used in these tests.")
    }

    func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument {
        fatalError("Not used in these tests.")
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        fatalError("Not used in these tests.")
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        createdProjectPatternCopyUploads.append(fileURL)
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return ProjectPatternCopy(
            ownerId: "user-a",
            projectId: projectId,
            sourcePatternDocumentId: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
            titleSnapshot: fileURL.deletingPathExtension().lastPathComponent,
            designerSnapshot: nil,
            fileNameSnapshot: fileURL.lastPathComponent,
            localCopyPath: nil,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
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

    func saveDrawingData(
        _ data: Data,
        for patternCopy: ProjectPatternCopy
    ) async throws -> ProjectPatternCopy {
        patternCopy
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        patternCopy
    }
}
