//
//  ProfileSettingsViewModel.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Combine
import Foundation

struct ProfileFormData {
    var displayName = ""
    var preferredUnits = "Metric"

    init() {
    }

    init(profile: UserProfile) {
        displayName = profile.displayName
        preferredUnits = profile.preferredUnits
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedPreferredUnits: String {
        preferredUnits.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedDisplayName.isEmpty && !trimmedPreferredUnits.isEmpty
    }
}

@MainActor
final class ProfileSettingsViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRetryingSync = false
    @Published var formData = ProfileFormData()

    private let profileRepository: any ProfileRepository
    private let authSessionStore: AuthSessionStore
    private let requiresAuthenticatedProfile: Bool

    init(profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
        self.authSessionStore = .shared
        self.requiresAuthenticatedProfile = false
    }

    init(
        profileRepository: any ProfileRepository,
        authSessionStore: AuthSessionStore,
        requiresAuthenticatedProfile: Bool
    ) {
        self.profileRepository = profileRepository
        self.authSessionStore = authSessionStore
        self.requiresAuthenticatedProfile = requiresAuthenticatedProfile
    }

    var hasProfileNeedingSync: Bool {
        profile?.syncStatus.needsSync == true
    }

    func loadProfile() async {
        guard canLoadProfile else {
            resetToSignedOutDefaults()
            return
        }

        do {
            let profile = try await profileRepository.fetchCurrentProfile()
            self.profile = profile
            formData = ProfileFormData(profile: profile)
            errorMessage = nil
        } catch LocalProfileRepositoryError.profileNotFound {
            profile = nil
            formData = ProfileFormData()
            errorMessage = nil
        } catch {
            errorMessage = "프로필을 불러오지 못했어요."
        }
    }

    private var canLoadProfile: Bool {
        !requiresAuthenticatedProfile || authSessionStore.currentSession != nil
    }

    private func resetToSignedOutDefaults() {
        profile = nil
        formData = ProfileFormData()
        errorMessage = nil
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadProfile()
        isRetryingSync = false
    }

    func saveProfile() async -> Bool {
        guard formData.canSave else {
            errorMessage = "표시 이름을 입력해 주세요."
            return false
        }

        let now = Date()
        let existingProfile = profile
        let profileToSave = UserProfile(
            id: existingProfile?.id ?? SampleData.ownerId,
            ownerId: existingProfile?.ownerId ?? SampleData.ownerId,
            displayName: formData.trimmedDisplayName,
            preferredUnits: formData.trimmedPreferredUnits,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingProfile?.deletedAt,
            syncStatus: existingProfile?.syncStatus ?? .localOnly
        )

        do {
            try await profileRepository.saveCurrentProfile(profileToSave)
            let reloadedProfile = try await profileRepository.fetchCurrentProfile()
            profile = reloadedProfile
            formData = ProfileFormData(profile: reloadedProfile)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "프로필을 저장하지 못했어요."
            return false
        }
    }
}
