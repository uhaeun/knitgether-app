import Foundation

@MainActor
final class OfflineFirstProfileRepository: ProfileRepository {
    private let local: LocalProfileRepository
    private let remote: any ProfileRepository

    init(
        local: LocalProfileRepository,
        remote: any ProfileRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        await syncPendingChanges()

        do {
            let remoteProfile = try await remote.fetchCurrentProfile()
            await local.cacheSyncedProfile(remoteProfile)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchCurrentProfile()
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localProfile = copyProfile(
            profile,
            syncStatus: localSaveSyncStatus(for: profile.syncStatus)
        )
        try await local.saveCurrentProfile(localProfile)

        let uploadProfile = copyProfile(
            profile,
            syncStatus: uploadSyncStatus(for: profile.syncStatus)
        )

        do {
            try await remote.saveCurrentProfile(uploadProfile)
            try await cacheServerProfileIfAvailable(fallback: uploadProfile)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    private func syncPendingChanges() async {
        guard let profile = await local.pendingProfileForSync() else {
            return
        }

        do {
            let uploadProfile = copyProfile(
                profile,
                syncStatus: profile.syncStatus == .pendingUpload ? .synced : .localOnly
            )
            try await remote.saveCurrentProfile(uploadProfile)
            try await cacheServerProfileIfAvailable(fallback: uploadProfile)
        } catch {
            if !shouldDefer(error) {
                return
            }
        }
    }

    private func cacheServerProfileIfAvailable(fallback profile: UserProfile) async throws {
        do {
            let serverProfile = try await remote.fetchCurrentProfile()
            try await local.markProfileSynced(serverProfile)
            return
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markProfileSynced(profile)
    }

    private func shouldDefer(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        if let apiError = error as? APIError,
           let statusCode = apiError.statusCode {
            return statusCode >= 500
        }

        return false
    }

    private func localSaveSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        switch syncStatus {
        case .synced, .pendingUpload:
            return .pendingUpload
        default:
            return .localOnly
        }
    }

    private func uploadSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        syncStatus == .pendingUpload ? .synced : syncStatus
    }

    private func copyProfile(
        _ profile: UserProfile,
        syncStatus: SyncStatus
    ) -> UserProfile {
        UserProfile(
            id: profile.id,
            ownerId: profile.ownerId,
            displayName: profile.displayName,
            preferredUnits: profile.preferredUnits,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            deletedAt: profile.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: UserProfile?,
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }
}

extension OfflineFirstProfileRepository: OfflineSyncFlushable {
    func flushPendingChanges() async -> Int {
        await syncPendingChanges()
        return await local.pendingProfileForSync() == nil ? 0 : 1
    }
}
