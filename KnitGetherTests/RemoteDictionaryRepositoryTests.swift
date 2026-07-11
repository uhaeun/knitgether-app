import Foundation
import Testing
@testable import KnitGether

struct RemoteDictionaryRepositoryTests {
    @Test func fetchTermsRequestsDictionaryEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/dictionary-terms")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[\(Self.termJSON)]".utf8))
        }

        let repository = Self.makeRepository(session: session)

        let terms = try await repository.fetchTerms()

        #expect(terms.count == 1)
        #expect(terms.first?.term == "K2TOG")
        #expect(terms.first?.fullName == "Knit two together")
        #expect(terms.first?.relatedSkillAbbreviations == "K,K2TOG")
        #expect(terms.first?.syncStatus == .synced)
    }

    @Test func saveNewTermPostsDictionaryPayload() async throws {
        let term = Self.term(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/dictionary-terms")
            #expect(request.httpMethod == "POST")

            let body = try Self.bodyData(from: request)
            let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(object["id"] as? String == "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
            #expect(object["term"] as? String == "K2TOG")
            #expect(object["fullName"] as? String == "Knit two together")
            #expect(object["description"] as? String == "Two stitches are knit together.")
            #expect(object["relatedSkillAbbreviations"] as? String == "K,K2TOG")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.termJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveTerm(term)
    }

    @Test func saveSyncedTermPatchesDictionaryPayload() async throws {
        let term = Self.term(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/dictionary-terms/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.termJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveTerm(term)
    }

    @Test func deleteTermDeletesDictionaryEndpoint() async throws {
        let termID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/dictionary-terms/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
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

        try await repository.deleteTerm(id: termID)
    }

    private static func makeRepository(session: URLSession) -> RemoteDictionaryRepository {
        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )
        return RemoteDictionaryRepository(apiClient: client)
    }

    private static func term(syncStatus: SyncStatus) -> DictionaryTerm {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return DictionaryTerm(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            ownerId: "user-a",
            term: "K2TOG",
            fullName: "Knit two together",
            description: "Two stitches are knit together.",
            relatedSkillAbbreviations: "K,K2TOG",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static let termJSON = """
    {
      "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "ownerId": "user-a",
      "term": "K2TOG",
      "fullName": "Knit two together",
      "description": "Two stitches are knit together.",
      "relatedSkillAbbreviations": "K,K2TOG",
      "createdAt": "2026-07-09T00:00:00.000Z",
      "updatedAt": "2026-07-09T00:05:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

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
