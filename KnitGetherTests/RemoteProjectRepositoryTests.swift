import Foundation
import Testing
@testable import KnitGether

struct RemoteProjectRepositoryTests {
    @Test func fetchProjectsRequestsProjectsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectsResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        let projects = try await repository.fetchProjects()

        #expect(projects.count == 1)
        guard let project = projects.first else {
            Issue.record("Expected one project")
            return
        }

        #expect(project.id.uuidString.lowercased() == "11111111-1111-4111-8111-111111111111")
        #expect(project.ownerId == "user-a")
        #expect(project.name == "Favorite Cardigan")
        #expect(project.status == .wip)
        #expect(project.isFavorite)
        #expect(project.memo == "Use smaller needles for ribbing.")
        #expect(project.patternCopy == nil)
        #expect(project.workspaceDisplayMode == .patternAndCounter)
        #expect(project.workspaceSheetPosition == .medium)
        #expect(project.rowCounter.currentRow == 42)
        #expect(project.rowCounter.targetRow == 120)
        #expect(project.workSessions.count == 1)
        #expect(project.workSessions.first?.memo == "Sleeve increases.")
        #expect(project.relatedSkillIds.map(\.uuidString).map { $0.lowercased() } == [
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        ])
        #expect(project.syncStatus == .synced)
    }

    @Test func fetchProjectRequestsProjectEndpointAndReturnsNilForNotFound() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())")
            #expect(request.httpMethod == "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"PROJECT_NOT_FOUND","message":"Project not found."}"#.utf8)
            )
        }

        let repository = Self.makeRepository(session: session)

        let project = try await repository.fetchProject(id: projectID)

        #expect(project == nil)
    }

    @Test func saveNewProjectPostsProjectPayload() async throws {
        let project = Self.project(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == "11111111-1111-4111-8111-111111111111")
            #expect(object["name"] as? String == "Favorite Cardigan")
            #expect(object["status"] as? String == "WIP")
            #expect(object["isFavorite"] as? Bool == true)
            #expect(object["memo"] as? String == "Use smaller needles for ribbing.")
            #expect(object["relatedSkillIds"] as? [String] == [
                "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            ])
            let rowCounter = try #require(object["rowCounter"] as? [String: Any])
            #expect(rowCounter["currentRow"] as? Int == 42)
            #expect(rowCounter["targetRow"] as? Int == 120)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveProject(project)
    }

    @Test func saveSyncedProjectPatchesProjectPayload() async throws {
        let project = Self.project(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveProject(project)
    }

    @Test func deleteProjectRequestsProjectDeleteEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())")
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

        try await repository.deleteProject(id: projectID)
    }

    private static func makeRepository(session: URLSession) -> RemoteProjectRepository {
        RemoteProjectRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            )
        )
    }

    private static func project(syncStatus: SyncStatus = .synced) -> KnittingProject {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let now = Date(timeIntervalSince1970: 1_783_071_200)

        return KnittingProject(
            id: projectID,
            ownerId: "user-a",
            name: "Favorite Cardigan",
            status: .wip,
            isFavorite: true,
            memo: "Use smaller needles for ribbing.",
            startDate: now,
            lastWorkedAt: now,
            patternCopy: nil,
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: projectID,
                currentRow: 42,
                targetRow: 120,
                createdAt: now,
                updatedAt: now
            ),
            workSessions: [],
            relatedSkillIds: [UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!],
            createdAt: now,
            updatedAt: now,
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

    private static let projectResponseJSON = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "ownerId": "user-a",
      "name": "Favorite Cardigan",
      "status": "WIP",
      "isFavorite": true,
      "memo": "Use smaller needles for ribbing.",
      "startDate": "2026-07-01T00:00:00.000Z",
      "lastWorkedAt": "2026-07-03T09:00:00.000Z",
      "patternCopy": null,
      "workspaceDisplayMode": "patternAndCounter",
      "workspaceSheetPosition": "medium",
      "rowCounter": {
        "id": "22222222-2222-4222-8222-222222222222",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "name": "Main Counter",
        "currentRow": 42,
        "targetRow": 120,
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "workSessions": [],
      "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectsResponseJSON = """
    [
      {
        "id": "11111111-1111-4111-8111-111111111111",
        "ownerId": "user-a",
        "name": "Favorite Cardigan",
        "status": "WIP",
        "isFavorite": true,
        "memo": "Use smaller needles for ribbing.",
        "startDate": "2026-07-01T00:00:00.000Z",
        "lastWorkedAt": "2026-07-03T09:00:00.000Z",
        "patternCopy": null,
        "workspaceDisplayMode": "patternAndCounter",
        "workspaceSheetPosition": "medium",
        "rowCounter": {
          "id": "22222222-2222-4222-8222-222222222222",
          "ownerId": "user-a",
          "projectId": "11111111-1111-4111-8111-111111111111",
          "name": "Main Counter",
          "currentRow": 42,
          "targetRow": 120,
          "createdAt": "2026-07-01T00:00:00.000Z",
          "updatedAt": "2026-07-03T09:00:00.000Z",
          "deletedAt": null,
          "syncStatus": "Synced"
        },
        "workSessions": [
          {
            "id": "33333333-3333-4333-8333-333333333333",
            "ownerId": "user-a",
            "projectId": "11111111-1111-4111-8111-111111111111",
            "startedAt": "2026-07-03T08:00:00.000Z",
            "endedAt": "2026-07-03T09:00:00.000Z",
            "memo": "Sleeve increases.",
            "createdAt": "2026-07-03T09:00:00.000Z",
            "updatedAt": "2026-07-03T09:00:00.000Z",
            "deletedAt": null,
            "syncStatus": "Synced"
          }
        ],
        "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      }
    ]
    """
}
