//
//  RemoteProfileRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

final class RemoteProfileRepository: ProfileRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        try await apiClient.get("profile")
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        let body = SaveProfileRequest(profile: profile)
        let _: UserProfile = try await apiClient.send(
            "profile",
            method: "PATCH",
            body: body
        )
    }
}

private struct SaveProfileRequest: Encodable {
    let displayName: String
    let preferredUnits: String

    init(profile: UserProfile) {
        displayName = profile.displayName
        preferredUnits = profile.preferredUnits
    }
}
