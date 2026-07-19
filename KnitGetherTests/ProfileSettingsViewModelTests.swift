import Foundation
import Testing
@testable import KnitGether

@MainActor
struct ProfileSettingsViewModelTests {
    @Test func loadProfilePopulatesFormData() async throws {
        let repository = FakeProfileRepository(profile: Self.makeProfile())
        let viewModel = ProfileSettingsViewModel(profileRepository: repository)

        await viewModel.loadProfile()

        #expect(viewModel.profile?.id == "user-a")
        #expect(viewModel.formData.displayName == "Local Knitter")
        #expect(viewModel.formData.preferredUnits == "Metric")
    }

    @Test func loadProfileWithoutSavedLocalProfileKeepsEditableDefaults() async throws {
        let repository = FakeProfileRepository(profile: Self.makeProfile())
        repository.fetchProfileError = LocalProfileRepositoryError.profileNotFound
        let viewModel = ProfileSettingsViewModel(profileRepository: repository)

        await viewModel.loadProfile()

        #expect(viewModel.profile == nil)
        #expect(viewModel.formData.displayName == "")
        #expect(viewModel.formData.preferredUnits == "Metric")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func saveProfilePersistsTrimmedProfileAndReloads() async throws {
        let repository = FakeProfileRepository(profile: Self.makeProfile())
        let viewModel = ProfileSettingsViewModel(profileRepository: repository)
        await viewModel.loadProfile()
        viewModel.formData.displayName = "  Yuha  "
        viewModel.formData.preferredUnits = "  Metric  "

        let didSave = await viewModel.saveProfile()

        #expect(didSave)
        #expect(repository.savedProfiles.count == 1)
        #expect(repository.savedProfiles[0].displayName == "Yuha")
        #expect(repository.savedProfiles[0].preferredUnits == "Metric")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func saveProfileRejectsMissingDisplayName() async throws {
        let repository = FakeProfileRepository(profile: Self.makeProfile())
        let viewModel = ProfileSettingsViewModel(profileRepository: repository)
        await viewModel.loadProfile()
        viewModel.formData.displayName = "   "

        let didSave = await viewModel.saveProfile()

        #expect(!didSave)
        #expect(repository.savedProfiles.isEmpty)
        #expect(viewModel.errorMessage == "표시 이름을 입력해 주세요.")
    }

    @Test func retrySyncReloadsProfileAndClearsPendingStatus() async throws {
        let pendingProfile = Self.makeProfile(syncStatus: .pendingUpload)
        let syncedProfile = Self.makeProfile(syncStatus: .synced)
        let repository = FakeProfileRepository(profile: pendingProfile)
        repository.profileFetchResults = [pendingProfile, syncedProfile]
        let viewModel = ProfileSettingsViewModel(profileRepository: repository)

        await viewModel.loadProfile()

        #expect(viewModel.hasProfileNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchProfileCallCount == 2)
        #expect(viewModel.profile?.syncStatus == .synced)
        #expect(!viewModel.hasProfileNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    private static func makeProfile(
        syncStatus: SyncStatus = .synced
    ) -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: "user-a",
            ownerId: "user-a",
            displayName: "Local Knitter",
            preferredUnits: "Metric",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }
}

@MainActor
private final class FakeProfileRepository: ProfileRepository {
    var profile: UserProfile
    var profileFetchResults: [UserProfile] = []
    var fetchProfileCallCount = 0
    var fetchProfileError: Error?
    var savedProfiles: [UserProfile] = []

    init(profile: UserProfile) {
        self.profile = profile
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        fetchProfileCallCount += 1

        if let fetchProfileError {
            throw fetchProfileError
        }

        if !profileFetchResults.isEmpty {
            profile = profileFetchResults.removeFirst()
        }

        return profile
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        savedProfiles.append(profile)
        self.profile = profile
    }
}
