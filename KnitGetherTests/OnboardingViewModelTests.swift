import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OnboardingViewModelTests {
    @Test func onboardingStepsIncludeAccountAndSkillTestPrompts() async throws {
        #expect(OnboardingViewModel.Step.allCases.count == 6)
        #expect(OnboardingViewModel.Step.ready.progressText == "6 / 6")
    }

    @Test func loadExistingProfilePopulatesForm() async throws {
        let repository = FakeOnboardingProfileRepository(profile: Self.makeProfile())
        let viewModel = OnboardingViewModel(profileRepository: repository)

        await viewModel.loadExistingProfileIfAvailable()

        #expect(viewModel.formData.displayName == "Yuha")
        #expect(viewModel.formData.preferredUnits == "US")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func completeOnboardingSavesDefaultDisplayNameWhenBlank() async throws {
        let repository = FakeOnboardingProfileRepository(profile: nil)
        let viewModel = OnboardingViewModel(profileRepository: repository)
        viewModel.formData.displayName = "   "
        viewModel.formData.preferredUnits = "Metric"

        let didComplete = await viewModel.completeOnboarding()

        #expect(didComplete)
        #expect(repository.savedProfiles.count == 1)
        #expect(repository.savedProfiles[0].displayName == "뜨개러")
        #expect(repository.savedProfiles[0].preferredUnits == "Metric")
        #expect(repository.savedProfiles[0].syncStatus == .localOnly)
    }

    @Test func completeOnboardingPreservesExistingProfileIdentity() async throws {
        let existingProfile = Self.makeProfile()
        let repository = FakeOnboardingProfileRepository(profile: existingProfile)
        let viewModel = OnboardingViewModel(profileRepository: repository)
        await viewModel.loadExistingProfileIfAvailable()
        viewModel.formData.displayName = "  Updated Knitter  "

        let didComplete = await viewModel.completeOnboarding()

        #expect(didComplete)
        #expect(repository.savedProfiles.count == 1)
        #expect(repository.savedProfiles[0].id == existingProfile.id)
        #expect(repository.savedProfiles[0].ownerId == existingProfile.ownerId)
        #expect(repository.savedProfiles[0].displayName == "Updated Knitter")
        #expect(repository.savedProfiles[0].syncStatus == existingProfile.syncStatus)
    }

    @Test func replacingProfileRepositoryUsesNewScopeWhenCompletingOnboarding() async throws {
        let oldRepository = FakeOnboardingProfileRepository(profile: nil)
        let newRepository = FakeOnboardingProfileRepository(profile: Self.makeProfile(id: "user-b"))
        let viewModel = OnboardingViewModel(profileRepository: oldRepository)
        viewModel.formData.displayName = "새 계정"

        viewModel.replaceProfileRepository(newRepository)
        await viewModel.loadExistingProfileIfAvailable()
        viewModel.formData.displayName = "새 계정"
        let didComplete = await viewModel.completeOnboarding()

        #expect(didComplete)
        #expect(oldRepository.savedProfiles.isEmpty)
        #expect(newRepository.savedProfiles.count == 1)
        #expect(newRepository.savedProfiles[0].id == "user-b")
        #expect(newRepository.savedProfiles[0].displayName == "새 계정")
    }

    private static func makeProfile(id: String = "user-a") -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: id,
            ownerId: id,
            displayName: "Yuha",
            preferredUnits: "US",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }
}

@MainActor
private final class FakeOnboardingProfileRepository: ProfileRepository {
    var profile: UserProfile?
    var savedProfiles: [UserProfile] = []

    init(profile: UserProfile?) {
        self.profile = profile
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        guard let profile else {
            throw LocalProfileRepositoryError.profileNotFound
        }

        return profile
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        savedProfiles.append(profile)
        self.profile = profile
    }
}
