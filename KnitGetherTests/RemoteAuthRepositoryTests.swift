import Foundation
import Testing
@testable import KnitGether

struct RemoteAuthRepositoryTests {
    @Test func loginPostsCredentialsAndDecodesSession() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/auth/login")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)

            let bodyString = String(decoding: try Self.bodyData(from: request), as: UTF8.self)
            #expect(bodyString.contains(#""email":"yuha@example.com""#))
            #expect(bodyString.contains(#""password":"password-1234""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.sessionJSON.utf8))
        }

        let repository = Self.makeRepository(session: session, token: nil)
        let authSession = try await repository.login(
            email: "yuha@example.com",
            password: "password-1234"
        )

        #expect(authSession.accessToken == "jwt-token")
        #expect(authSession.profile.displayName == "Yuha")
    }

    @Test func registerPostsProfileDataAndDecodesSession() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/auth/register")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)

            let bodyString = String(decoding: try Self.bodyData(from: request), as: UTF8.self)
            #expect(bodyString.contains(#""email":"yuha@example.com""#))
            #expect(bodyString.contains(#""password":"password-1234""#))
            #expect(bodyString.contains(#""displayName":"Yuha""#))
            #expect(bodyString.contains(#""preferredUnits":"Metric""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.sessionJSON.utf8))
        }

        let repository = Self.makeRepository(session: session, token: nil)
        let authSession = try await repository.register(
            email: "yuha@example.com",
            password: "password-1234",
            displayName: "Yuha",
            preferredUnits: "Metric"
        )

        #expect(authSession.accessToken == "jwt-token")
        #expect(authSession.profile.ownerId == "user-a")
    }

    @Test func fetchCurrentUserRequestsMeEndpointWithBearerToken() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/auth/me")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.userJSON.utf8))
        }

        let repository = Self.makeRepository(session: session, token: "jwt-token")
        let user = try await repository.fetchCurrentUser()

        #expect(user.id == "user-a")
        #expect(user.email == "yuha@example.com")
        #expect(user.profile.displayName == "Yuha")
    }

    private static func makeRepository(
        session: URLSession,
        token: String?
    ) -> RemoteAuthRepository {
        RemoteAuthRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { token }
                ),
                session: session
            )
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

    private static let sessionJSON = """
    {
      "accessToken":"jwt-token",
      "tokenType":"Bearer",
      "profile":{
        "id":"user-a",
        "ownerId":"user-a",
        "displayName":"Yuha",
        "preferredUnits":"Metric",
        "createdAt":"2026-07-09T02:00:00.000Z",
        "updatedAt":"2026-07-09T02:05:00.000Z",
        "deletedAt":null,
        "syncStatus":"Synced"
      }
    }
    """

    private static let userJSON = """
    {
      "id":"user-a",
      "email":"yuha@example.com",
      "profile":{
        "id":"user-a",
        "ownerId":"user-a",
        "displayName":"Yuha",
        "preferredUnits":"Metric",
        "createdAt":"2026-07-09T02:00:00.000Z",
        "updatedAt":"2026-07-09T02:05:00.000Z",
        "deletedAt":null,
        "syncStatus":"Synced"
      }
    }
    """
}
