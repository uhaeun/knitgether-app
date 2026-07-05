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
        throw APIError.unsupportedOperation("RemoteProjectRepository.saveProject is not supported yet.")
    }

    func deleteProject(id: UUID) async throws {
        throw APIError.unsupportedOperation("RemoteProjectRepository.deleteProject is not supported yet.")
    }
}
