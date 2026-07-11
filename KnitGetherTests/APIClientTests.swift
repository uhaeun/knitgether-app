import Foundation
import Testing
@testable import KnitGether

struct APIClientTests {
    @Test func getAddsAuthorizationHeaderAndDecodesResponse() async throws {
        struct ResponseBody: Decodable, Equatable {
            let value: String
        }

        let session = MockURLProtocol.makeSession { request in
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
        let recorder = AuthFailureRecorder()
        let session = MockURLProtocol.makeSession { request in
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
                authTokenProvider: { nil },
                authFailureHandler: {
                    recorder.record()
                }
            ),
            session: session
        )

        do {
            let _: [String] = try await client.get("projects")
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 401)
            #expect(error.code == "UNAUTHENTICATED")
            #expect(recorder.count == 1)
        }
    }

    @Test func getDoesNotNotifyAuthFailureForNonUnauthorizedHTTPFailure() async throws {
        let recorder = AuthFailureRecorder()
        let session = MockURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"FORBIDDEN","message":"Access denied."}"#.utf8)
            )
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { nil },
                authFailureHandler: {
                    recorder.record()
                }
            ),
            session: session
        )

        do {
            let _: [String] = try await client.get("projects")
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 403)
            #expect(error.code == "FORBIDDEN")
            #expect(recorder.count == 0)
        }
    }

    @Test func uploadMultipartAddsAuthorizationAndDecodesResponse() async throws {
        struct ResponseBody: Decodable, Equatable {
            let id: String
        }

        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
            let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
            #expect(contentType.hasPrefix("multipart/form-data; boundary="))

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#"name="title""#))
            #expect(bodyString.contains("Cozy Shawl"))
            #expect(bodyString.contains(#"name="file"; filename="cozy-shawl.pdf""#))
            #expect(bodyString.contains("application/pdf"))
            #expect(bodyString.contains("%PDF-1.4"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"id":"44444444-4444-4444-8444-444444444444"}"#.utf8))
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )

        let response: ResponseBody = try await client.uploadMultipart(
            "patterns",
            fields: ["title": "Cozy Shawl"],
            file: MultipartFile(
                fieldName: "file",
                fileName: "cozy-shawl.pdf",
                contentType: "application/pdf",
                data: Data("%PDF-1.4".utf8)
            )
        )

        #expect(response == ResponseBody(id: "44444444-4444-4444-8444-444444444444"))
    }

    @Test func downloadDataReturnsBinaryResponse() async throws {
        let pdfData = Data("%PDF-1.4".utf8)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, pdfData)
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )

        let data = try await client.downloadData("patterns/44444444-4444-4444-8444-444444444444/file")
        #expect(data == pdfData)
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

private final class AuthFailureRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }

    func record() {
        lock.lock()
        defer { lock.unlock() }
        _count += 1
    }
}
