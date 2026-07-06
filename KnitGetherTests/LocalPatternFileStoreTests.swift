import Foundation
import Testing
@testable import KnitGether

struct LocalPatternFileStoreTests {
    @Test func storeLibraryPatternDataWritesFileUnderPatternDirectory() throws {
        let rootURL = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let patternID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
        let store = LocalPatternFileStore(rootDirectoryURL: rootURL)

        let storedFile = try store.storeLibraryPatternData(
            Data("%PDF-1.4".utf8),
            fileName: "cozy/shawl.pdf",
            patternId: patternID
        )

        #expect(storedFile.fileName == "cozy-shawl.pdf")
        #expect(storedFile.relativePath == "Patterns/\(patternID.uuidString)/cozy-shawl.pdf")
        let fileURL = try #require(store.fileURL(for: storedFile.relativePath))
        #expect(try Data(contentsOf: fileURL) == Data("%PDF-1.4".utf8))
    }

    @Test func copyLibraryPatternFileToProjectCopiesCachedPattern() throws {
        let rootURL = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let patternID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let copyID = UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
        let now = Date(timeIntervalSince1970: 1_783_071_200)
        let store = LocalPatternFileStore(rootDirectoryURL: rootURL)
        let storedPattern = try store.storeLibraryPatternData(
            Data("%PDF-1.4".utf8),
            fileName: "cozy-shawl.pdf",
            patternId: patternID
        )
        let pattern = PatternDocument(
            id: patternID,
            ownerId: "user-a",
            title: "Cozy Shawl",
            designer: "Yu",
            fileName: storedPattern.fileName,
            localFilePath: storedPattern.relativePath,
            pageCount: 12,
            notes: "Use lace markers.",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )

        let copiedFile = try #require(
            try store.copyLibraryPatternFileToProject(
                pattern,
                projectId: projectID,
                copyId: copyID
            )
        )

        #expect(copiedFile.relativePath == "Projects/\(projectID.uuidString)/Patterns/\(copyID.uuidString)/cozy-shawl.pdf")
        let copiedURL = try #require(store.fileURL(for: copiedFile.relativePath))
        #expect(try Data(contentsOf: copiedURL) == Data("%PDF-1.4".utf8))
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalPatternFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
