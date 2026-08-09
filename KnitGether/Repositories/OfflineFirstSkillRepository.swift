import Foundation

@MainActor
final class OfflineFirstSkillRepository: SkillRepository {
    private let local: LocalSkillRepository
    private let remote: any SkillRepository

    init(
        local: LocalSkillRepository,
        remote: any SkillRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchSkills() async throws -> [Skill] {
        await syncPendingChanges()

        do {
            let remoteSkills = try await remote.fetchSkills()
            try await local.cacheSyncedSkills(remoteSkills, pruningStaleEntries: true)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchSkills()
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        await syncPendingChanges()

        do {
            if let remoteSkill = try await remote.fetchSkill(id: id) {
                try await local.cacheSyncedSkills([remoteSkill])
            }
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchSkill(id: id)
    }

    func saveSkill(_ skill: Skill) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localSkill = copySkill(
            skill,
            syncStatus: localSaveSyncStatus(for: skill.syncStatus)
        )
        try await local.saveSkill(localSkill)

        let uploadSkill = copySkill(
            skill,
            syncStatus: uploadSyncStatus(for: skill.syncStatus)
        )

        do {
            try await remote.saveSkill(uploadSkill)
            try await cacheServerSkillIfAvailable(fallback: uploadSkill)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill {
        let rollbackSnapshot = await local.makeRollbackSnapshot()

        guard let existingSkill = try await local.fetchSkill(id: skillId) else {
            let remoteSkill = try await remote.saveSkillLevel(skillId: skillId, level: level)
            try await local.cacheSyncedSkills([remoteSkill])
            return remoteSkill
        }

        let localSkill = copySkill(
            existingSkill,
            userLevel: level,
            syncStatus: localSaveSyncStatus(for: existingSkill.syncStatus)
        )
        try await local.saveSkill(localSkill)

        do {
            let remoteSkill = try await remote.saveSkillLevel(skillId: skillId, level: level)
            try await local.markSkillSynced(remoteSkill)
            return remoteSkill
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
            return localSkill
        }
    }

    func deleteSkill(id: UUID) async throws {
        let existingSkill = try await local.fetchSkill(id: id)
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteSkill(id: id)

        guard existingSkill?.syncStatus != .localOnly else {
            try await local.removeSkillTombstone(id: id)
            return
        }

        do {
            try await remote.deleteSkill(id: id)
            try await local.removeSkillTombstone(id: id)
        } catch {
            if shouldTreatDeleteAsSynced(error) {
                try await local.removeSkillTombstone(id: id)
                return
            }

            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        do {
            return try await remote.fetchSkillAnimations()
        } catch {
            guard shouldDefer(error) else {
                throw error
            }

            return try await local.fetchSkillAnimations()
        }
    }

    private func syncPendingChanges() async {
        for skill in await local.pendingSkillsForSync() {
            do {
                if skill.syncStatus == .pendingDelete {
                    try await remote.deleteSkill(id: skill.id)
                    try await local.removeSkillTombstone(id: skill.id)
                } else {
                    let uploadSkill = copySkill(
                        skill,
                        syncStatus: skill.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    if skill.isSystem {
                        let syncedSkill = try await remote.saveSkillLevel(
                            skillId: skill.id,
                            level: persistedSkillLevel(for: skill)
                        )
                        try await local.markSkillSynced(syncedSkill)
                    } else {
                        try await remote.saveSkill(uploadSkill)
                        if let userLevel = skill.userLevel {
                            _ = try await remote.saveSkillLevel(
                                skillId: skill.id,
                                level: userLevel
                            )
                        }
                        try await cacheServerSkillIfAvailable(fallback: uploadSkill)
                    }
                }
            } catch {
                await resolveRejectedPendingChange(skill, after: error)
            }
        }
    }

    private func resolveRejectedPendingChange(
        _ skill: Skill,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch skill.syncStatus {
        case .localOnly, .pendingDelete:
            try? await local.removeSkillTombstone(id: skill.id)
        case .pendingUpload:
            do {
                if let serverSkill = try await remote.fetchSkill(id: skill.id) {
                    try await local.markSkillSynced(serverSkill)
                } else {
                    try await local.removeSkillTombstone(id: skill.id)
                }
            } catch {
                if !shouldDefer(error) {
                    try? await local.removeSkillTombstone(id: skill.id)
                }
            }
        default:
            break
        }
    }

    private func cacheServerSkillIfAvailable(fallback skill: Skill) async throws {
        do {
            if let serverSkill = try await remote.fetchSkill(id: skill.id) {
                try await local.markSkillSynced(serverSkill)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markSkillSynced(skill)
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

    private func shouldTreatDeleteAsSynced(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.statusCode == 404
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

    private func persistedSkillLevel(for skill: Skill) -> String {
        guard let userLevel = skill.userLevel, !userLevel.isEmpty else {
            return "몰라요"
        }

        return userLevel == "애매해요" ? "헷갈려요" : userLevel
    }

    private func copySkill(
        _ skill: Skill,
        userLevel: String? = nil,
        syncStatus: SyncStatus
    ) -> Skill {
        Skill(
            id: skill.id,
            ownerId: skill.ownerId,
            name: skill.name,
            abbreviation: skill.abbreviation,
            description: skill.description,
            category: skill.category,
            difficulty: skill.difficulty,
            animationName: skill.animationName,
            animationType: skill.animationType,
            isSystem: skill.isSystem,
            userLevel: userLevel ?? skill.userLevel,
            createdAt: skill.createdAt,
            updatedAt: skill.updatedAt,
            deletedAt: skill.deletedAt,
            syncStatus: syncStatus,
            steps: skill.steps,
            animationIds: skill.animationIds
        )
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: [Skill],
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }
}
