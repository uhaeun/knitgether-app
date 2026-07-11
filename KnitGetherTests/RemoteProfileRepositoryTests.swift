import Foundation
import Testing
@testable import KnitGether

struct RemoteProfileRepositoryTests {
    @Test func fetchCurrentProfileRequestsProfileEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/profile")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.profileJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let profile = try await repository.fetchCurrentProfile()

        #expect(profile.id == "user-a")
        #expect(profile.ownerId == "user-a")
        #expect(profile.displayName == "Local Knitter")
        #expect(profile.preferredUnits == "Metric")
        #expect(profile.syncStatus == .synced)
    }

    @Test func saveCurrentProfilePatchesProfilePayload() async throws {
        let profile = Self.makeProfile()
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/profile")
            #expect(request.httpMethod == "PATCH")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let bodyString = String(decoding: try Self.bodyData(from: request), as: UTF8.self)
            #expect(bodyString.contains(#""displayName":"Local Knitter""#))
            #expect(bodyString.contains(#""preferredUnits":"Metric""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.profileJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveCurrentProfile(profile)
    }

    private static func makeRepository(session: URLSession) -> RemoteProfileRepository {
        RemoteProfileRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            )
        )
    }

    private static func makeProfile() -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: "user-a",
            ownerId: "user-a",
            displayName: "Local Knitter",
            preferredUnits: "Metric",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
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

    private static let profileJSON = """
    {
      "id":"user-a",
      "ownerId":"user-a",
      "displayName":"Local Knitter",
      "preferredUnits":"Metric",
      "createdAt":"2026-07-09T02:00:00.000Z",
      "updatedAt":"2026-07-09T02:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """
}
