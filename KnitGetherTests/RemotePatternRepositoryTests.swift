import Foundation
import Testing
@testable import KnitGether

struct RemotePatternRepositoryTests {
    @Test func fetchPatternsRequestsPatternsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.patternsResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let patterns = try await repository.fetchPatterns()

        #expect(patterns.count == 1)
        #expect(patterns.first?.id.uuidString.lowercased() == "44444444-4444-4444-8444-444444444444")
        #expect(patterns.first?.title == "Cozy Shawl")
        #expect(patterns.first?.syncStatus == .synced)
    }

    @Test func createPatternUploadsPdfAndCachesDownload() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sourceURL = tempDirectory.appendingPathComponent("cozy-shawl.pdf")
        try Data("%PDF-1.4".utf8).write(to: sourceURL)
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
                let body = try Self.bodyData(from: request)
                let bodyString = String(decoding: body, as: UTF8.self)
                #expect(bodyString.contains(#"filename="cozy-shawl.pdf""#))
                #expect(bodyString.contains("%PDF-1.4"))

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.patternResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )
        let pattern = try await repository.createPattern(fromFileAt: sourceURL)

        #expect(callCount == 2)
        #expect(pattern.localFilePath?.contains("Patterns/44444444-4444-4444-8444-444444444444") == true)
        let cachedURL = try #require(repository.fileURL(for: pattern))
        #expect(FileManager.default.fileExists(atPath: cachedURL.path))
    }

    @Test func fetchPatternDownloadsFileWhenCacheIsMissing() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444")
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.patternResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )
        let pattern = try #require(
            try await repository.fetchPattern(id: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!)
        )

        #expect(callCount == 2)
        #expect(repository.fileURL(for: pattern) != nil)
    }

    @Test func deletePatternRequestsDeleteEndpoint() async throws {
        let patternID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/\(patternID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session)
        try await repository.deletePattern(id: patternID)
    }

    @Test func createProjectPatternCopyUploadsPdfToLibraryAndCachesProjectCopy() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sourceURL = tempDirectory.appendingPathComponent("project-shawl.pdf")
        try Data("%PDF-1.4".utf8).write(to: sourceURL)
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
                #expect(request.httpMethod == "POST")
                let body = try Self.bodyData(from: request)
                let bodyString = String(decoding: body, as: UTF8.self)
                #expect(bodyString.contains(#"filename="project-shawl.pdf""#))

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.patternResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )
        let patternCopy = try await repository.createProjectPatternCopy(
            fromFileAt: sourceURL,
            forProjectId: projectID
        )

        #expect(callCount == 2)
        #expect(patternCopy.sourcePatternDocumentId?.uuidString.lowercased() == "44444444-4444-4444-8444-444444444444")
        #expect(patternCopy.localCopyPath?.contains("Projects/11111111-1111-4111-8111-111111111111/Patterns/") == true)
        let copyURL = try #require(repository.fileURL(for: patternCopy))
        #expect(FileManager.default.fileExists(atPath: copyURL.path))
    }

    @Test func saveDrawingDataUploadsDrawingAndCachesLocalCopy() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let drawingData = Data("PKDRAWING".utf8)
        let patternCopy = Self.patternCopy()
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/drawing")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#"filename="drawing.pkdrawing""#))
            #expect(bodyString.contains("PKDRAWING"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectPatternCopyWithDrawingResponseJSON.utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )
        let updatedPatternCopy = try await repository.saveDrawingData(
            drawingData,
            for: patternCopy
        )

        #expect(callCount == 1)
        let drawingPath = try #require(updatedPatternCopy.drawingDataPath)
        #expect(drawingPath.hasSuffix("drawing.pkdrawing"))
        let cachedURL = tempDirectory
            .appendingPathComponent("cache", isDirectory: true)
            .appendingPathComponent(drawingPath)
        #expect(try Data(contentsOf: cachedURL) == drawingData)
        #expect(updatedPatternCopy.drawingUpdatedAt != nil)
    }

    private static func makeRepository(
        session: URLSession,
        cacheRootURL: URL? = nil
    ) -> RemotePatternRepository {
        RemotePatternRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            ),
            fileStore: LocalPatternFileStore(
                fileManager: .default,
                rootDirectoryURL: cacheRootURL
            )
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemotePatternRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func patternCopy() -> ProjectPatternCopy {
        let now = Date(timeIntervalSince1970: 1_783_071_200)

        return ProjectPatternCopy(
            id: UUID(uuidString: "66666666-6666-4666-8666-666666666666")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            sourcePatternDocumentId: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
            titleSnapshot: "Cozy Shawl",
            designerSnapshot: "Yu",
            fileNameSnapshot: "cozy-shawl.pdf",
            localCopyPath: "Projects/11111111-1111-4111-8111-111111111111/Patterns/66666666-6666-4666-8666-666666666666/cozy-shawl.pdf",
            pageCountSnapshot: 12,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func bodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let bodyStream = request.httpBodyStream else {
            Issue.record("Expected request body")
            return Data()
        }

        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        let bufferSize = 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while bodyStream.hasBytesAvailable {
            let readCount = bodyStream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if readCount == 0 {
                break
            }
            data.append(buffer, count: readCount)
        }

        return data
    }

    private static let patternResponseJSON = """
    {
      "id": "44444444-4444-4444-8444-444444444444",
      "ownerId": "user-a",
      "title": "Cozy Shawl",
      "designer": "Yu",
      "fileName": "cozy-shawl.pdf",
      "localFilePath": null,
      "pageCount": 12,
      "notes": "Use lace markers.",
      "createdAt": "2026-07-04T00:00:00.000Z",
      "updatedAt": "2026-07-05T00:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectPatternCopyWithDrawingResponseJSON = """
    {
      "id": "66666666-6666-4666-8666-666666666666",
      "ownerId": "user-a",
      "projectId": "11111111-1111-4111-8111-111111111111",
      "sourcePatternDocumentId": "44444444-4444-4444-8444-444444444444",
      "titleSnapshot": "Cozy Shawl",
      "designerSnapshot": "Yu",
      "fileNameSnapshot": "cozy-shawl.pdf",
      "localCopyPath": null,
      "pageCountSnapshot": 12,
      "drawingDataPath": null,
      "drawingUpdatedAt": "2026-07-05T13:00:00.000Z",
      "copiedAt": "2026-07-04T12:00:00.000Z",
      "createdAt": "2026-07-04T12:00:00.000Z",
      "updatedAt": "2026-07-05T12:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let patternsResponseJSON = """
    [
      {
        "id": "44444444-4444-4444-8444-444444444444",
        "ownerId": "user-a",
        "title": "Cozy Shawl",
        "designer": "Yu",
        "fileName": "cozy-shawl.pdf",
        "localFilePath": null,
        "pageCount": 12,
        "notes": "Use lace markers.",
        "createdAt": "2026-07-04T00:00:00.000Z",
        "updatedAt": "2026-07-05T00:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      }
    ]
    """
}
