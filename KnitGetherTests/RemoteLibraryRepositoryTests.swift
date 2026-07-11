import Foundation
import Testing
@testable import KnitGether

@MainActor
struct RemoteLibraryRepositoryTests {
    @Test func fetchYarnsRequestsYarnsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/yarns")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnsJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let yarns = try await repository.fetchYarns()

        #expect(yarns.count == 1)
        #expect(yarns[0].id.uuidString.lowercased() == "cccccccc-cccc-4ccc-8ccc-cccccccccccc")
        #expect(yarns[0].name == "Soft Merino DK")
        #expect(yarns[0].brand == "Sample Yarn Co.")
        #expect(yarns[0].colorway == "Cloud Gray")
        #expect(yarns[0].weight == "DK")
        #expect(yarns[0].quantity == 5)
        #expect(yarns[0].syncStatus == .synced)
    }

    @Test func fetchNeedlesRequestsNeedlesEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/needles")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.needlesJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let needles = try await repository.fetchNeedles()

        #expect(needles.count == 1)
        #expect(needles[0].id.uuidString.lowercased() == "dddddddd-dddd-4ddd-8ddd-dddddddddddd")
        #expect(needles[0].name == "Wood Circular Needle")
        #expect(needles[0].needleType == "Circular")
        #expect(needles[0].size == "5.0 mm")
        #expect(needles[0].length == "80 cm")
        #expect(needles[0].syncStatus == .synced)
    }

    @Test func saveNewYarnPostsYarnPayload() async throws {
        let yarn = Self.makeYarn(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/yarns")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let bodyString = String(decoding: try Self.bodyData(from: request), as: UTF8.self)
            #expect(bodyString.contains(#""id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc""#))
            #expect(bodyString.contains(#""name":"Soft Merino DK""#))
            #expect(bodyString.contains(#""brand":"Sample Yarn Co.""#))
            #expect(bodyString.contains(#""quantity":5"#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveYarn(yarn)
    }

    @Test func saveSyncedYarnPatchesYarnPayload() async throws {
        let yarn = Self.makeYarn(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/yarns/cccccccc-cccc-4ccc-8ccc-cccccccccccc")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveYarn(yarn)
    }

    @Test func deleteYarnRequestsDeleteEndpoint() async throws {
        let yarnID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/yarns/\(yarnID.uuidString.lowercased())")
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
        try await repository.deleteYarn(id: yarnID)
    }

    @Test func fetchYarnUsagesRequestsProjectYarnUsageEndpointAndDecodesResponse() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/yarn-usages")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnUsagesJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let usages = try await repository.fetchYarnUsages(forProjectId: projectID)

        #expect(usages.count == 1)
        #expect(usages[0].id.uuidString.lowercased() == "99999999-9999-4999-8999-999999999999")
        #expect(usages[0].projectId == projectID)
        #expect(usages[0].yarnId.uuidString.lowercased() == "cccccccc-cccc-4ccc-8ccc-cccccccccccc")
        #expect(usages[0].yarnNameSnapshot == "Soft Merino DK")
        #expect(usages[0].quantityUsed == 2)
        #expect(usages[0].memo == "Sleeve swatch")
        #expect(usages[0].syncStatus == .synced)
    }

    @Test func fetchYarnUsagesForYarnRequestsYarnUsageEndpointAndDecodesProjectName() async throws {
        let yarnID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/yarns/\(yarnID.uuidString.lowercased())/usages")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnUsagesJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let usages = try await repository.fetchYarnUsages(forYarnId: yarnID)

        #expect(usages.count == 1)
        #expect(usages[0].projectNameSnapshot == "Favorite Cardigan")
        #expect(usages[0].quantityUsed == 2)
    }

    @Test func recordYarnUsagePostsProjectYarnUsagePayload() async throws {
        let usage = Self.makeYarnUsage(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/yarn-usages")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let object = try #require(
                JSONSerialization.jsonObject(with: try Self.bodyData(from: request)) as? [String: Any]
            )
            #expect(object["id"] as? String == "99999999-9999-4999-8999-999999999999")
            #expect(object["yarnId"] as? String == "cccccccc-cccc-4ccc-8ccc-cccccccccccc")
            #expect(object["yarnNameSnapshot"] as? String == "Soft Merino DK")
            #expect(object["quantityUsed"] as? Int == 2)
            #expect(object["memo"] as? String == "Sleeve swatch")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnUsageJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedUsage = try await repository.recordYarnUsage(usage)

        #expect(savedUsage.id == usage.id)
        #expect(savedUsage.quantityUsed == 2)
    }

    @Test func updateYarnUsagePatchesProjectYarnUsagePayload() async throws {
        let usage = Self.makeYarnUsage(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/yarn-usages/99999999-9999-4999-8999-999999999999")
            #expect(request.httpMethod == "PATCH")

            let object = try #require(
                JSONSerialization.jsonObject(with: try Self.bodyData(from: request)) as? [String: Any]
            )
            #expect(object["quantityUsed"] as? Int == 2)
            #expect(object["memo"] as? String == "Sleeve swatch")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.yarnUsageJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let updatedUsage = try await repository.updateYarnUsage(usage)

        #expect(updatedUsage.id == usage.id)
        #expect(updatedUsage.quantityUsed == 2)
    }

    @Test func deleteYarnUsageRequestsProjectYarnUsageDeleteEndpoint() async throws {
        let usage = Self.makeYarnUsage(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/yarn-usages/99999999-9999-4999-8999-999999999999")
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
        try await repository.deleteYarnUsage(usage)
    }

    @Test func saveNewNeedlePostsNeedlePayload() async throws {
        let needle = Self.makeNeedle(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/needles")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let bodyString = String(decoding: try Self.bodyData(from: request), as: UTF8.self)
            #expect(bodyString.contains(#""id":"dddddddd-dddd-4ddd-8ddd-dddddddddddd""#))
            #expect(bodyString.contains(#""name":"Wood Circular Needle""#))
            #expect(bodyString.contains(#""needleType":"Circular""#))
            #expect(bodyString.contains(#""size":"5.0 mm""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.needleJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveNeedle(needle)
    }

    @Test func saveSyncedNeedlePatchesNeedlePayload() async throws {
        let needle = Self.makeNeedle(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/needles/dddddddd-dddd-4ddd-8ddd-dddddddddddd")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.needleJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveNeedle(needle)
    }

    @Test func deleteNeedleRequestsDeleteEndpoint() async throws {
        let needleID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/needles/\(needleID.uuidString.lowercased())")
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
        try await repository.deleteNeedle(id: needleID)
    }

    @Test func fetchToolsRequestsToolsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/tools")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.toolsJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let tools = try await repository.fetchTools()

        #expect(tools.count == 1)
        #expect(tools[0].id.uuidString.lowercased() == "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")
        #expect(tools[0].name == "Locking Marker Set")
        #expect(tools[0].type == "Marker")
        #expect(tools[0].link == "example.com/marker")
        #expect(tools[0].usageCount == 2)
        #expect(tools[0].syncStatus == .synced)
    }

    @Test func saveNewToolPostsToolPayload() async throws {
        let tool = Self.makeTool(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/tools")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let object = try #require(
                JSONSerialization.jsonObject(with: try Self.bodyData(from: request)) as? [String: Any]
            )
            #expect(object["id"] as? String == "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")
            #expect(object["name"] as? String == "Locking Marker Set")
            #expect(object["type"] as? String == "Marker")
            #expect(object["link"] as? String == "example.com/marker")
            #expect(object["memo"] as? String == "Raglan increases.")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.toolJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveTool(tool)
    }

    @Test func deleteToolRequestsDeleteEndpoint() async throws {
        let toolID = UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/tools/\(toolID.uuidString.lowercased())")
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
        try await repository.deleteTool(id: toolID)
    }

    @Test func fetchProjectToolsRequestsProjectToolEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/projects/\(projectID.uuidString.lowercased())/tools")
            #expect(request.httpMethod == "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.toolsJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let tools = try await repository.fetchTools(forProjectId: projectID)

        #expect(tools.map { $0.id.uuidString.lowercased() } == ["eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"])
    }

    @Test func linkToolRequestsProjectToolLinkEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let tool = Self.makeTool(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/projects/\(projectID.uuidString.lowercased())/tools/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")
            #expect(request.httpMethod == "POST")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.toolJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let linkedTool = try await repository.linkTool(tool, toProjectId: projectID)

        #expect(linkedTool.id == tool.id)
    }

    @Test func unlinkToolRequestsProjectToolUnlinkEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let tool = Self.makeTool(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/library/projects/\(projectID.uuidString.lowercased())/tools/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")
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
        try await repository.unlinkTool(tool, fromProjectId: projectID)
    }

    private static func makeRepository(session: URLSession) -> RemoteLibraryRepository {
        RemoteLibraryRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            )
        )
    }

    private static func makeYarn(syncStatus: SyncStatus) -> Yarn {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return Yarn(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            ownerId: "user-a",
            name: "Soft Merino DK",
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: 5,
            notes: "Reserved for beanie and swatches.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeNeedle(syncStatus: SyncStatus) -> Needle {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return Needle(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            ownerId: "user-a",
            name: "Wood Circular Needle",
            needleType: "Circular",
            size: "5.0 mm",
            length: "80 cm",
            notes: "Used for cardigan body.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeYarnUsage(syncStatus: SyncStatus) -> ProjectYarnUsage {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ProjectYarnUsage(
            id: UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            yarnId: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            yarnNameSnapshot: "Soft Merino DK",
            quantityUsed: 2,
            memo: "Sleeve swatch",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeTool(syncStatus: SyncStatus) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ToolItem(
            id: UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
            ownerId: "user-a",
            name: "Locking Marker Set",
            type: "Marker",
            link: "example.com/marker",
            memo: "Raglan increases.",
            usageCount: 2,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
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

    private static let yarnsJSON = """
    [\(yarnJSON)]
    """

    private static let yarnJSON = """
    {
      "id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
      "ownerId":"user-a",
      "name":"Soft Merino DK",
      "brand":"Sample Yarn Co.",
      "colorway":"Cloud Gray",
      "weight":"DK",
      "quantity":5,
      "notes":"Reserved for beanie and swatches.",
      "createdAt":"2026-07-09T01:00:00.000Z",
      "updatedAt":"2026-07-09T01:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """

    private static let yarnUsagesJSON = """
    [\(yarnUsageJSON)]
    """

    private static let yarnUsageJSON = """
    {
      "id":"99999999-9999-4999-8999-999999999999",
      "ownerId":"user-a",
      "projectId":"11111111-1111-4111-8111-111111111111",
      "projectNameSnapshot":"Favorite Cardigan",
      "yarnId":"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
      "yarnNameSnapshot":"Soft Merino DK",
      "quantityUsed":2,
      "memo":"Sleeve swatch",
      "usedAt":"2026-07-09T01:00:00.000Z",
      "createdAt":"2026-07-09T01:00:00.000Z",
      "updatedAt":"2026-07-09T01:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """

    private static let needlesJSON = """
    [\(needleJSON)]
    """

    private static let needleJSON = """
    {
      "id":"dddddddd-dddd-4ddd-8ddd-dddddddddddd",
      "ownerId":"user-a",
      "name":"Wood Circular Needle",
      "needleType":"Circular",
      "size":"5.0 mm",
      "length":"80 cm",
      "notes":"Used for cardigan body.",
      "createdAt":"2026-07-09T01:00:00.000Z",
      "updatedAt":"2026-07-09T01:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """

    private static let toolsJSON = """
    [\(toolJSON)]
    """

    private static let toolJSON = """
    {
      "id":"eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
      "ownerId":"user-a",
      "name":"Locking Marker Set",
      "type":"Marker",
      "link":"example.com/marker",
      "memo":"Raglan increases.",
      "usageCount":2,
      "createdAt":"2026-07-09T01:00:00.000Z",
      "updatedAt":"2026-07-09T01:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """
}
