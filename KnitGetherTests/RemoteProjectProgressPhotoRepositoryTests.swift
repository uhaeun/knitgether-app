import Foundation
import Testing
@testable import KnitGether

struct RemoteProjectProgressPhotoRepositoryTests {
    @Test func fetchProgressPhotosDownloadsRemoteFilesIntoLocalStore() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let projectID = Self.projectID
        let photoID = Self.photoID
        let imageData = Data("JPEGDATA".utf8)
        var requestedURLs: [String] = []

        let session = MockURLProtocol.makeSession { request in
            requestedURLs.append(request.url?.absoluteString ?? "")

            if request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos" {
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data("[\(Self.photoJSON(id: photoID, projectID: projectID))]".utf8))
            }

            if request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos/\(photoID.uuidString.lowercased())/file" {
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "image/jpeg"]
                )!
                return (response, imageData)
            }

            throw URLError(.badURL)
        }

        let repository = Self.makeRepository(session: session, rootURL: tempDirectory)

        let photos = try await repository.fetchProgressPhotos(projectId: projectID)

        let photo = try #require(photos.first)
        let localFilePath = try #require(photo.localFilePath)
        let localURL = try #require(repository.fileURL(for: photo))

        #expect(photos.count == 1)
        #expect(photo.id == photoID)
        #expect(localFilePath.contains("Projects/\(projectID.uuidString)/ProgressPhotos/\(photoID.uuidString)/front.jpg"))
        #expect(try Data(contentsOf: localURL) == imageData)
        #expect(requestedURLs == [
            "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos",
            "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos/\(photoID.uuidString.lowercased())/file",
        ])
    }

    @Test func createProgressPhotoUploadsMultipartAndCachesImage() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let projectID = Self.projectID
        let responsePhotoID = Self.photoID
        let imageData = Data("JPEGDATA".utf8)

        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
            let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
            #expect(contentType.hasPrefix("multipart/form-data; boundary="))

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#"name="id""#))
            #expect(bodyString.contains(#"name="caption""#))
            #expect(bodyString.contains("Front panel"))
            #expect(bodyString.contains(#"name="takenAt""#))
            #expect(bodyString.contains("2026-07-09T10:00:00.000Z"))
            #expect(bodyString.contains(#"name="file"; filename="front.jpg""#))
            #expect(bodyString.contains("image/jpeg"))
            #expect(bodyString.contains("JPEGDATA"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.photoJSON(id: responsePhotoID, projectID: projectID).utf8))
        }

        let repository = Self.makeRepository(session: session, rootURL: tempDirectory)

        let photo = try await repository.createProgressPhoto(
            projectId: projectID,
            imageData: imageData,
            fileName: "front.jpg",
            contentType: "image/jpeg",
            caption: "Front panel",
            takenAt: Self.date("2026-07-09T10:00:00.000Z")
        )

        let localURL = try #require(repository.fileURL(for: photo))
        #expect(photo.id == responsePhotoID)
        #expect(photo.syncStatus == .synced)
        #expect(try Data(contentsOf: localURL) == imageData)
    }

    @Test func updateProgressPhotoPatchesMetadataAndPreservesLocalFilePath() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let projectID = Self.projectID
        let photoID = Self.photoID
        let originalPhoto = Self.photo(projectID: projectID, photoID: photoID, localFilePath: "cached/front.jpg")

        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos/\(photoID.uuidString.lowercased())")
            #expect(request.httpMethod == "PATCH")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try Self.bodyData(from: request)
            let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(object["caption"] as? String == "Updated front")
            #expect(object["takenAt"] as? String == "2026-07-10T10:00:00.000Z")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(Self.photoJSON(
                    id: photoID,
                    projectID: projectID,
                    caption: "Updated front",
                    takenAt: "2026-07-10T10:00:00.000Z"
                ).utf8)
            )
        }

        let repository = Self.makeRepository(session: session, rootURL: tempDirectory)

        let updatedPhoto = try await repository.updateProgressPhoto(
            originalPhoto,
            caption: "  Updated front  ",
            takenAt: Self.date("2026-07-10T10:00:00.000Z")
        )

        #expect(updatedPhoto.caption == "Updated front")
        #expect(updatedPhoto.takenAt == Self.date("2026-07-10T10:00:00.000Z"))
        #expect(updatedPhoto.localFilePath == "cached/front.jpg")
        #expect(updatedPhoto.syncStatus == .synced)
    }

    @Test func deleteProgressPhotoDeletesRemoteRecordAndCachedFile() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let projectID = Self.projectID
        let photoID = Self.photoID
        let fileStore = LocalProjectProgressPhotoFileStore(rootDirectoryURL: tempDirectory)
        let storedFile = try fileStore.storePhotoData(
            Data("JPEGDATA".utf8),
            fileName: "front.jpg",
            projectId: projectID,
            photoId: photoID
        )
        let photo = Self.photo(
            projectID: projectID,
            photoID: photoID,
            localFilePath: storedFile.relativePath
        )

        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/progress-photos/\(photoID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session, rootURL: tempDirectory, fileStore: fileStore)
        let cachedURL = try #require(fileStore.fileURL(for: storedFile.relativePath))

        try await repository.deleteProgressPhoto(photo)

        #expect(!FileManager.default.fileExists(atPath: cachedURL.path))
    }

    private static let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    private static let photoID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!

    private static func makeRepository(
        session: URLSession,
        rootURL: URL,
        fileStore: LocalProjectProgressPhotoFileStore? = nil
    ) -> RemoteProjectProgressPhotoRepository {
        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )
        return RemoteProjectProgressPhotoRepository(
            apiClient: client,
            fileStore: fileStore ?? LocalProjectProgressPhotoFileStore(rootDirectoryURL: rootURL)
        )
    }

    private static func photo(
        projectID: UUID,
        photoID: UUID,
        localFilePath: String? = nil
    ) -> ProjectProgressPhoto {
        ProjectProgressPhoto(
            id: photoID,
            ownerId: "user-a",
            projectId: projectID,
            fileName: "front.jpg",
            contentType: "image/jpeg",
            byteSize: 8,
            localFilePath: localFilePath,
            caption: "Front panel",
            takenAt: date("2026-07-09T10:00:00.000Z"),
            createdAt: date("2026-07-09T10:00:00.000Z"),
            updatedAt: date("2026-07-09T10:00:00.000Z"),
            syncStatus: .synced
        )
    }

    private static func photoJSON(
        id: UUID,
        projectID: UUID,
        caption: String = "Front panel",
        takenAt: String = "2026-07-09T10:00:00.000Z"
    ) -> String {
        """
        {
          "id": "\(id.uuidString.lowercased())",
          "ownerId": "user-a",
          "projectId": "\(projectID.uuidString.lowercased())",
          "fileName": "front.jpg",
          "contentType": "image/jpeg",
          "byteSize": 8,
          "caption": "\(caption)",
          "takenAt": "\(takenAt)",
          "createdAt": "2026-07-09T10:00:00.000Z",
          "updatedAt": "\(takenAt)",
          "deletedAt": null,
          "syncStatus": "Synced"
        }
        """
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("KnitGetherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)!
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
}
