//
//  AppRepositoryContainer.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

final class AppRepositoryContainer {
    static let shared = AppRepositoryContainer.makeDefault()

    let projectRepository: any ProjectRepository
    let patternRepository: any PatternRepository
    let libraryRepository: any LibraryRepository
    let skillRepository: any SkillRepository
    let profileRepository: any ProfileRepository

    init(
        projectRepository: any ProjectRepository = LocalProjectRepository(),
        patternRepository: any PatternRepository = LocalPatternRepository(),
        libraryRepository: any LibraryRepository = LocalLibraryRepository(),
        skillRepository: any SkillRepository = LocalSkillRepository(),
        profileRepository: any ProfileRepository = LocalProfileRepository()
    ) {
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.profileRepository = profileRepository
    }

    static func makeDefault(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        session: URLSession = .shared
    ) -> AppRepositoryContainer {
        let projectRepository: any ProjectRepository

        if let baseURL = apiBaseURL(from: environment) {
            let token = environment["KNITGETHER_DEV_AUTH_TOKEN"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let apiClient = APIClient(
                configuration: APIConfiguration(
                    baseURL: baseURL,
                    authTokenProvider: {
                        guard let token, !token.isEmpty else {
                            return nil
                        }
                        return token
                    }
                ),
                session: session
            )
            projectRepository = RemoteProjectRepository(apiClient: apiClient)
        } else {
            projectRepository = LocalProjectRepository()
        }

        return AppRepositoryContainer(projectRepository: projectRepository)
    }

    private static func apiBaseURL(from environment: [String: String]) -> URL? {
        guard
            let value = environment["KNITGETHER_API_BASE_URL"]?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty,
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return nil
        }

        return url
    }
}
