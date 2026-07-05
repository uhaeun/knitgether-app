import Foundation

final class RemoteProjectRepository: ProjectRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProjects() async throws -> [KnittingProject] {
        try await apiClient.get("projects")
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        do {
            return try await apiClient.get("projects/\(id.uuidString.lowercased())")
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveProject(_ project: KnittingProject) async throws {
        let body = SaveProjectRequest(project: project)

        if project.syncStatus == .synced {
            let _: KnittingProject = try await apiClient.send(
                "projects/\(project.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: KnittingProject = try await apiClient.send(
                "projects",
                method: "POST",
                body: body
            )
        }
    }

    func deleteProject(id: UUID) async throws {
        try await apiClient.delete("projects/\(id.uuidString.lowercased())")
    }
}

private struct SaveProjectRequest: Encodable {
    let id: String
    let name: String
    let status: String
    let isFavorite: Bool
    let memo: String
    let startDate: Date
    let lastWorkedAt: Date?
    let workspaceDisplayMode: String?
    let workspaceSheetPosition: String?
    let relatedSkillIds: [String]
    let rowCounter: SaveRowCounterRequest
    let workSessions: [SaveWorkSessionRequest]

    nonisolated init(project: KnittingProject) {
        id = project.id.uuidString.lowercased()
        name = project.name
        status = project.status.rawValue
        isFavorite = project.isFavorite
        memo = project.memo
        startDate = project.startDate
        lastWorkedAt = project.lastWorkedAt
        workspaceDisplayMode = project.workspaceDisplayMode?.rawValue
        workspaceSheetPosition = project.workspaceSheetPosition?.rawValue
        relatedSkillIds = project.relatedSkillIds.map { $0.uuidString.lowercased() }
        rowCounter = SaveRowCounterRequest(rowCounter: project.rowCounter)
        workSessions = project.workSessions.map(SaveWorkSessionRequest.init)
    }
}

private struct SaveRowCounterRequest: Encodable {
    let id: String
    let projectId: String
    let name: String
    let currentRow: Int
    let targetRow: Int?

    nonisolated init(rowCounter: RowCounter) {
        id = rowCounter.id.uuidString.lowercased()
        projectId = rowCounter.projectId.uuidString.lowercased()
        name = rowCounter.name
        currentRow = rowCounter.currentRow
        targetRow = rowCounter.targetRow
    }
}

private struct SaveWorkSessionRequest: Encodable {
    let id: String
    let projectId: String
    let startedAt: Date
    let endedAt: Date?
    let memo: String?

    nonisolated init(workSession: WorkSession) {
        id = workSession.id.uuidString.lowercased()
        projectId = workSession.projectId.uuidString.lowercased()
        startedAt = workSession.startedAt
        endedAt = workSession.endedAt
        memo = workSession.memo
    }
}
