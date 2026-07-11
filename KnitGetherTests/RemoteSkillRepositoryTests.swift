import Foundation
import Testing
@testable import KnitGether

@MainActor
struct RemoteSkillRepositoryTests {
    @Test func fetchSkillsRequestsSkillsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.skillsJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let skills = try await repository.fetchSkills()

        #expect(skills.count == 1)
        #expect(skills[0].id.uuidString.lowercased() == "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
        #expect(skills[0].name == "Knit")
        #expect(skills[0].abbreviation == "K")
        #expect(skills[0].isSystem)
        #expect(skills[0].userLevel == "헷갈려요")
        #expect(skills[0].steps == ["Insert right needle.", "Wrap yarn.", "Pull through."])
        #expect(skills[0].animationIds.map { $0.uuidString.lowercased() } == [
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
        ])
        #expect(skills[0].syncStatus == .synced)
    }

    @Test func fetchSkillRequestsSkillEndpointAndReturnsNilForNotFound() async throws {
        let skillID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        var callCount = 0
        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills/\(skillID.uuidString.lowercased())")
                #expect(request.httpMethod == "GET")

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.skillJSON.utf8))
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"code":"SKILL_NOT_FOUND"}"#.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let skill = try #require(try await repository.fetchSkill(id: skillID))
        let missingSkill = try await repository.fetchSkill(id: skillID)

        #expect(skill.name == "Knit")
        #expect(missingSkill == nil)
    }

    @Test func saveNewSkillPostsSkillPayload() async throws {
        let skill = Self.makeSkill(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#""name":"Knit""#))
            #expect(bodyString.contains(#""abbreviation":"K""#))
            #expect(bodyString.contains(#""steps":["Insert right needle.","Wrap yarn.","Pull through."]"#))
            #expect(bodyString.contains(#""animationIds":["bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"]"#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.skillJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveSkill(skill)
    }

    @Test func saveSyncedSkillPatchesSkillPayload() async throws {
        let skill = Self.makeSkill(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.skillJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        try await repository.saveSkill(skill)
    }

    @Test func saveSkillLevelPatchesLevelEndpoint() async throws {
        let skillID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills/\(skillID.uuidString.lowercased())/level")
            #expect(request.httpMethod == "PATCH")

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#""level":"잘 알아요""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.knownSkillJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedSkill = try await repository.saveSkillLevel(skillId: skillID, level: "잘 알아요")

        #expect(savedSkill.userLevel == "잘 알아요")
        #expect(savedSkill.isSystem)
    }

    @Test func deleteSkillRequestsDeleteEndpoint() async throws {
        let skillID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skills/\(skillID.uuidString.lowercased())")
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
        try await repository.deleteSkill(id: skillID)
    }

    @Test func fetchSkillAnimationsRequestsSkillAnimationsEndpoint() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/skill-animations")
            #expect(request.httpMethod == "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.skillAnimationsJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let animations = try await repository.fetchSkillAnimations()

        #expect(animations.count == 1)
        #expect(animations[0].title == "Knit stitch loop")
        #expect(animations[0].skillId?.uuidString.lowercased() == "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
        #expect(animations[0].syncStatus == .synced)
    }

    private static func makeRepository(session: URLSession) -> RemoteSkillRepository {
        RemoteSkillRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            )
        )
    }

    private static func makeSkill(syncStatus: SyncStatus) -> Skill {
        let now = Date(timeIntervalSince1970: 1_783_728_000)
        return Skill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            ownerId: "user-a",
            name: "Knit",
            abbreviation: "K",
            description: "Knit stitch.",
            category: "기초",
            difficulty: "잘 알아요",
            animationName: "knit-loop",
            animationType: "loop",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus,
            steps: ["Insert right needle.", "Wrap yarn.", "Pull through."],
            animationIds: [
                UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
            ]
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

    private static let skillsJSON = """
    [\(skillJSON)]
    """

    private static let skillJSON = """
    {
      "id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "ownerId":"user-a",
      "name":"Knit",
      "abbreviation":"K",
      "description":"Knit stitch.",
      "category":"기초",
      "difficulty":"기초",
      "animationName":"knit-loop",
      "animationType":"loop",
      "isSystem":true,
      "userLevel":"헷갈려요",
      "createdAt":"2026-07-09T00:00:00.000Z",
      "updatedAt":"2026-07-09T00:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced",
      "steps":["Insert right needle.","Wrap yarn.","Pull through."],
      "animationIds":["bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"]
    }
    """

    private static let knownSkillJSON = """
    {
      "id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "ownerId":"system",
      "name":"Knit",
      "abbreviation":"K",
      "description":"Knit stitch.",
      "category":"기초",
      "difficulty":"기초",
      "animationName":"knit-loop",
      "animationType":"loop",
      "isSystem":true,
      "userLevel":"잘 알아요",
      "createdAt":"2026-07-09T00:00:00.000Z",
      "updatedAt":"2026-07-09T00:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced",
      "steps":["Insert right needle.","Wrap yarn.","Pull through."],
      "animationIds":["bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"]
    }
    """

    private static let skillAnimationsJSON = """
    [{
      "id":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      "ownerId":"user-a",
      "skillId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "title":"Knit stitch loop",
      "localAssetName":"knit-loop",
      "durationSeconds":8,
      "createdAt":"2026-07-09T00:00:00.000Z",
      "updatedAt":"2026-07-09T00:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }]
    """
}
