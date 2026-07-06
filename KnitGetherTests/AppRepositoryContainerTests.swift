import Foundation
import Testing
@testable import KnitGether

struct AppRepositoryContainerTests {
    @Test func makeDefaultUsesLocalRepositoriesWhenAPIBaseURLIsMissing() {
        let container = AppRepositoryContainer.makeDefault(environment: [:])

        #expect(container.projectRepository is LocalProjectRepository)
        #expect(container.patternRepository is LocalPatternRepository)
        #expect(container.libraryRepository is LocalLibraryRepository)
        #expect(container.skillRepository is LocalSkillRepository)
        #expect(container.profileRepository is LocalProfileRepository)
    }

    @Test func makeDefaultUsesRemoteRepositoriesWhenAPIBaseURLIsConfigured() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects" {
                return (response, Data("[]".utf8))
            }

            #expect(request.url?.absoluteString == "https://api.knitgether.test/api/v1/patterns")
            return (response, Data("[]".utf8))
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_DEV_AUTH_TOKEN": "dev-token",
            ],
            session: session
        )

        #expect(container.projectRepository is RemoteProjectRepository)
        #expect(container.patternRepository is RemotePatternRepository)
        #expect(container.libraryRepository is LocalLibraryRepository)
        #expect(container.skillRepository is LocalSkillRepository)
        #expect(container.profileRepository is LocalProfileRepository)

        let projects = try await container.projectRepository.fetchProjects()
        #expect(projects.isEmpty)

        let patterns = try await container.patternRepository.fetchPatterns()
        #expect(patterns.isEmpty)
    }
}
