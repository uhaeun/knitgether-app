import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstProfileRepositoryTests {
    @Test func fetchProfileFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let localProfile = Self.makeProfile(syncStatus: .synced)
        let local = LocalProfileRepository(profile: localProfile)
        let remote = ProfileRepositoryFake(profile: localProfile)
        remote.fetchProfileError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProfileRepository(local: local, remote: remote)

        let profile = try await repository.fetchCurrentProfile()

        #expect(profile.id == localProfile.id)
        #expect(profile.displayName == "Local Knitter")
    }

    @Test func saveProfileKeepsPendingUploadAndFlushesOnNextSuccessfulFetch() async throws {
        let profile = Self.makeProfile(syncStatus: .synced)
        let local = LocalProfileRepository(profile: profile)
        let remote = ProfileRepositoryFake(profile: profile)
        remote.saveProfileError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstProfileRepository(local: local, remote: remote)
        let updatedProfile = Self.makeProfile(displayName: "Yuha", syncStatus: .synced)

        try await repository.saveCurrentProfile(updatedProfile)

        #expect(try await local.fetchCurrentProfile().syncStatus == .pendingUpload)
        #expect(remote.savedProfiles.isEmpty)

        remote.saveProfileError = nil
        remote.profile = Self.makeProfile(displayName: "Yuha", syncStatus: .synced)

        let syncedProfile = try await repository.fetchCurrentProfile()

        #expect(remote.savedProfiles.map(\.displayName) == ["Yuha"])
        #expect(remote.savedProfiles.map(\.syncStatus) == [.synced])
        #expect(syncedProfile.syncStatus == .synced)
    }

    @Test func savePendingProfileUploadsAsExistingProfileWhenRemoteIsAvailable() async throws {
        let profile = Self.makeProfile(syncStatus: .pendingUpload)
        let local = LocalProfileRepository(profile: profile)
        let remote = ProfileRepositoryFake(profile: profile)
        let repository = OfflineFirstProfileRepository(local: local, remote: remote)

        try await repository.saveCurrentProfile(profile)

        #expect(remote.savedProfiles.map(\.id) == [profile.id])
        #expect(remote.savedProfiles.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchCurrentProfile().syncStatus == .synced)
    }

    @Test func saveProfileCachesServerVersionAfterSuccessfulUpload() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let profile = Self.makeProfile(displayName: "Local Knitter", syncStatus: .localOnly)
        let serverProfile = Self.makeProfile(displayName: "Server Knitter", syncStatus: .synced)
        let local = LocalProfileRepository(
            seedSample: false,
            fileURL: tempDirectory.appendingPathComponent("profile.json")
        )
        let remote = ProfileRepositoryFake(profile: profile)
        remote.profileAfterSave = serverProfile
        let repository = OfflineFirstProfileRepository(local: local, remote: remote)

        try await repository.saveCurrentProfile(profile)

        let cachedProfile = try await local.fetchCurrentProfile()
        #expect(cachedProfile.displayName == "Server Knitter")
        #expect(cachedProfile.syncStatus == .synced)
    }

    private static func makeProfile(
        displayName: String = "Local Knitter",
        syncStatus: SyncStatus
    ) -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: "user-a",
            ownerId: "user-a",
            displayName: displayName,
            preferredUnits: "Metric",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OfflineFirstProfileRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

@MainActor
private final class ProfileRepositoryFake: ProfileRepository {
    var profile: UserProfile
    var profileAfterSave: UserProfile?
    var savedProfiles: [UserProfile] = []
    var fetchProfileError: Error?
    var saveProfileError: Error?

    init(profile: UserProfile) {
        self.profile = profile
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        if let fetchProfileError {
            throw fetchProfileError
        }

        return profile
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        if let saveProfileError {
            throw saveProfileError
        }

        savedProfiles.append(profile)
        self.profile = profileAfterSave ?? profile
    }
}
