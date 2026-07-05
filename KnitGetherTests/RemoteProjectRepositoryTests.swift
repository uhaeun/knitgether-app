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

        #expect(project.id.uuidString.lowercased() == "11111111-1111-1111-1111-111111111111")
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
            "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        ])
        #expect(project.syncStatus == .synced)
    }

    @Test func fetchProjectRequestsProjectEndpointAndReturnsNilForNotFound() async throws {
        let projectID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
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

    @Test func saveProjectThrowsUnsupportedOperation() async throws {
        let repository = Self.makeRepository(session: URLSession(configuration: .ephemeral))

        do {
            try await repository.saveProject(Self.project())
            Issue.record("Expected APIError.unsupportedOperation")
        } catch let error as APIError {
            guard case let .unsupportedOperation(message) = error else {
                Issue.record("Expected unsupported operation, got \(error)")
                return
            }
            #expect(message.contains("saveProject"))
        }
    }

    @Test func deleteProjectThrowsUnsupportedOperation() async throws {
        let repository = Self.makeRepository(session: URLSession(configuration: .ephemeral))

        do {
            try await repository.deleteProject(id: UUID())
            Issue.record("Expected APIError.unsupportedOperation")
        } catch let error as APIError {
            guard case let .unsupportedOperation(message) = error else {
                Issue.record("Expected unsupported operation, got \(error)")
                return
            }
            #expect(message.contains("deleteProject"))
        }
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

    private static func project() -> KnittingProject {
        let projectID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
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
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static let projectsResponseJSON = """
    [
      {
        "id": "11111111-1111-1111-1111-111111111111",
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
          "id": "22222222-2222-2222-2222-222222222222",
          "ownerId": "user-a",
          "projectId": "11111111-1111-1111-1111-111111111111",
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
            "id": "33333333-3333-3333-3333-333333333333",
            "ownerId": "user-a",
            "projectId": "11111111-1111-1111-1111-111111111111",
            "startedAt": "2026-07-03T08:00:00.000Z",
            "endedAt": "2026-07-03T09:00:00.000Z",
            "memo": "Sleeve increases.",
            "createdAt": "2026-07-03T09:00:00.000Z",
            "updatedAt": "2026-07-03T09:00:00.000Z",
            "deletedAt": null,
            "syncStatus": "Synced"
          }
        ],
        "relatedSkillIds": ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"],
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      }
    ]
    """
}
