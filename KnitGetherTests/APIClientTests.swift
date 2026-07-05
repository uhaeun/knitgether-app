import Foundation
import Testing
@testable import KnitGether

struct APIClientTests {
    @Test func getAddsAuthorizationHeaderAndDecodesResponse() async throws {
        struct ResponseBody: Decodable, Equatable {
            let value: String
        }

        let session = Self.makeMockSession()
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )

        let body: ResponseBody = try await client.get("projects")
        #expect(body == ResponseBody(value: "ok"))
    }

    @Test func getThrowsStructuredErrorForHTTPFailure() async throws {
        let session = Self.makeMockSession()
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"UNAUTHENTICATED","message":"Missing or invalid bearer token.","details":{}}"#.utf8)
            )
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { nil }
            ),
            session: session
        )

        do {
            let _: [String] = try await client.get("projects")
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 401)
            #expect(error.code == "UNAUTHENTICATED")
        }
    }

    private static func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
