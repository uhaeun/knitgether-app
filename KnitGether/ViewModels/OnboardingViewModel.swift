//
//  OnboardingViewModel.swift
//  KnitGether
//
//  Created by Codex on 7/10/26.
//

import Combine
import Foundation

struct OnboardingFormData {
    var displayName = "뜨개러"
    var preferredUnits = "Metric"

    init() {
    }

    init(profile: UserProfile) {
        displayName = profile.displayName
        preferredUnits = profile.preferredUnits
    }

    var normalizedDisplayName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "뜨개러" : trimmed
    }

    var normalizedPreferredUnits: String {
        let trimmed = preferredUnits.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Metric" : trimmed
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case intro
        case account
        case profile
        case skillTest
        case ready

        var progressText: String {
            "\(rawValue + 1) / \(Self.allCases.count)"
        }
    }

    @Published var currentStep: Step = .intro
    @Published var formData = OnboardingFormData()
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSaving = false

    private var profileRepository: any ProfileRepository
    private var existingProfile: UserProfile?
    private var didLoadExistingProfile = false

    init(profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
    }

    var canGoBack: Bool {
        currentStep.rawValue > Step.intro.rawValue
    }

    var isLastStep: Bool {
        currentStep == .ready
    }

    func goNext() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
            return
        }

        currentStep = nextStep
    }

    func goBack() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else {
            return
        }

        currentStep = previousStep
    }

    func replaceProfileRepository(_ profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
        existingProfile = nil
        didLoadExistingProfile = false
    }

    func loadExistingProfileIfAvailable() async {
        guard !didLoadExistingProfile else {
            return
        }

        didLoadExistingProfile = true

        do {
            let profile = try await profileRepository.fetchCurrentProfile()
            existingProfile = profile
            formData = OnboardingFormData(profile: profile)
            errorMessage = nil
        } catch {
            existingProfile = nil
            errorMessage = nil
        }
    }

    func completeOnboarding() async -> Bool {
        guard !isSaving else {
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let profile = UserProfile(
            id: existingProfile?.id ?? SampleData.ownerId,
            ownerId: existingProfile?.ownerId ?? SampleData.ownerId,
            displayName: formData.normalizedDisplayName,
            preferredUnits: formData.normalizedPreferredUnits,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingProfile?.deletedAt,
            syncStatus: existingProfile?.syncStatus ?? .localOnly
        )

        do {
            try await profileRepository.saveCurrentProfile(profile)
            existingProfile = profile
            errorMessage = nil
            return true
        } catch {
            errorMessage = "시작 정보를 저장하지 못했어요."
            return false
        }
    }
}
