import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstSkillRepositoryTests {
    @Test func fetchSkillsFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let localSkill = Self.makeSkill(syncStatus: .synced)
        let local = LocalSkillRepository(skills: [localSkill], animations: [])
        let remote = SkillRepositoryFake()
        remote.fetchSkillsError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        let skills = try await repository.fetchSkills()

        #expect(skills.map(\.id) == [localSkill.id])
    }

    @Test func saveNewSkillKeepsLocalChangeAndFlushesOnNextSuccessfulFetch() async throws {
        let local = LocalSkillRepository(skills: [], animations: [])
        let remote = SkillRepositoryFake()
        remote.saveSkillError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)
        let skill = Self.makeSkill(syncStatus: .localOnly)

        try await repository.saveSkill(skill)

        #expect(try await local.fetchSkills().map(\.syncStatus) == [.localOnly])
        #expect(remote.savedSkills.isEmpty)

        remote.saveSkillError = nil
        remote.remoteSkills = [skill.copy(syncStatus: .synced)]

        let syncedSkills = try await repository.fetchSkills()

        #expect(remote.savedSkills.map(\.id) == [skill.id])
        #expect(remote.savedSkills.map(\.syncStatus) == [.localOnly])
        #expect(syncedSkills.map(\.syncStatus) == [.synced])
    }

    @Test func saveSyncedSkillKeepsPendingUploadAndFlushesAsSyncedOnNextFetch() async throws {
        let skill = Self.makeSkill(syncStatus: .synced)
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        remote.saveSkillError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)
        let updatedSkill = skill.copy(name: "Purl", syncStatus: .synced)

        try await repository.saveSkill(updatedSkill)

        #expect(try await local.fetchSkills().map(\.syncStatus) == [.pendingUpload])

        remote.saveSkillError = nil
        remote.remoteSkills = [updatedSkill.copy(syncStatus: .synced)]

        _ = try await repository.fetchSkills()

        #expect(remote.savedSkills.map(\.id) == [skill.id])
        #expect(remote.savedSkills.map(\.syncStatus) == [.synced])
    }

    @Test func savePendingSkillUploadsAsExistingSkillWhenRemoteIsAvailable() async throws {
        let skill = Self.makeSkill(syncStatus: .pendingUpload)
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        try await repository.saveSkill(skill)

        #expect(remote.savedSkills.map(\.id) == [skill.id])
        #expect(remote.savedSkills.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchSkills().map(\.syncStatus) == [.synced])
    }

    @Test func saveSkillCachesServerVersionAfterSuccessfulUpload() async throws {
        let skill = Self.makeSkill(name: "Local Knit", syncStatus: .localOnly)
        let serverSkill = Self.makeSkill(name: "Server Knit", syncStatus: .synced)
        let local = LocalSkillRepository(skills: [], animations: [])
        let remote = SkillRepositoryFake()
        remote.remoteSkills = [serverSkill]
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        try await repository.saveSkill(skill)

        let cachedSkill = try #require(await local.fetchSkill(id: skill.id))
        #expect(cachedSkill.name == "Server Knit")
        #expect(cachedSkill.syncStatus == .synced)
    }

    @Test func saveSystemSkillLevelUsesLevelEndpointInsteadOfFullSkillUpdate() async throws {
        let skill = Self.makeSkill(
            isSystem: true,
            userLevel: "몰라요",
            syncStatus: .synced
        )
        let serverSkill = skill.copy(userLevel: "잘 알아요", syncStatus: .synced)
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        remote.remoteSkills = [skill]
        remote.savedLevelResponses = [serverSkill]
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        let updatedSkill = try await repository.saveSkillLevel(
            skillId: skill.id,
            level: "잘 알아요"
        )

        #expect(updatedSkill.userLevel == "잘 알아요")
        #expect(remote.savedLevels.map(\.skillId) == [skill.id])
        #expect(remote.savedLevels.map(\.level) == ["잘 알아요"])
        #expect(remote.savedSkills.isEmpty)
        #expect(try await local.fetchSkill(id: skill.id)?.userLevel == "잘 알아요")
        #expect(try await local.fetchSkill(id: skill.id)?.syncStatus == .synced)
    }

    @Test func pendingSystemSkillLevelRetriesWithLevelEndpoint() async throws {
        let skill = Self.makeSkill(
            isSystem: true,
            userLevel: "몰라요",
            syncStatus: .synced
        )
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        remote.remoteSkills = [skill]
        remote.saveSkillLevelError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        let localSkill = try await repository.saveSkillLevel(
            skillId: skill.id,
            level: "헷갈려요"
        )

        #expect(localSkill.userLevel == "헷갈려요")
        #expect(try await local.fetchSkill(id: skill.id)?.syncStatus == .pendingUpload)
        #expect(remote.savedSkills.isEmpty)

        remote.saveSkillLevelError = nil
        remote.savedLevelResponses = [skill.copy(userLevel: "헷갈려요", syncStatus: .synced)]

        _ = try await repository.fetchSkills()

        #expect(remote.savedLevels.map(\.skillId) == [skill.id, skill.id])
        #expect(remote.savedLevels.map(\.level) == ["헷갈려요", "헷갈려요"])
        #expect(remote.savedSkills.isEmpty)
        #expect(try await local.fetchSkill(id: skill.id)?.syncStatus == .synced)
        #expect(try await local.fetchSkill(id: skill.id)?.userLevel == "헷갈려요")
    }

    @Test func deleteSkillKeepsHiddenPendingDeleteAndFlushesOnNextFetch() async throws {
        let skill = Self.makeSkill(syncStatus: .synced)
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        remote.deleteSkillError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        try await repository.deleteSkill(id: skill.id)

        #expect(try await local.fetchSkills().isEmpty)
        #expect(await local.pendingSkillsForSync().map(\.syncStatus) == [.pendingDelete])
        #expect(remote.deletedSkillIDs.isEmpty)

        remote.deleteSkillError = nil

        _ = try await repository.fetchSkills()

        #expect(remote.deletedSkillIDs == [skill.id])
        #expect(await local.pendingSkillsForSync().isEmpty)
    }

    @Test func deleteLocalOnlySkillDoesNotCallRemoteDelete() async throws {
        let skill = Self.makeSkill(syncStatus: .localOnly)
        let local = LocalSkillRepository(skills: [skill], animations: [])
        let remote = SkillRepositoryFake()
        let repository = OfflineFirstSkillRepository(local: local, remote: remote)

        try await repository.deleteSkill(id: skill.id)

        #expect(remote.deletedSkillIDs.isEmpty)
        #expect(try await local.fetchSkills().isEmpty)
        #expect(await local.pendingSkillsForSync().isEmpty)
    }

    private static func makeSkill(
        id: UUID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
        name: String = "Knit",
        isSystem: Bool = false,
        userLevel: String? = nil,
        syncStatus: SyncStatus
    ) -> Skill {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Skill(
            id: id,
            ownerId: "user-a",
            name: name,
            abbreviation: "K",
            description: "Knit stitch.",
            category: "Basics",
            difficulty: "New",
            animationName: "Knit loop",
            animationType: "loop",
            isSystem: isSystem,
            userLevel: userLevel,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus,
            steps: ["Insert right needle.", "Wrap yarn."],
            animationIds: []
        )
    }
}

@MainActor
private final class SkillRepositoryFake: SkillRepository {
    var remoteSkills: [Skill] = []
    var remoteAnimations: [SkillAnimation] = []
    var savedSkills: [Skill] = []
    var savedLevels: [(skillId: UUID, level: String)] = []
    var savedLevelResponses: [Skill] = []
    var deletedSkillIDs: [UUID] = []
    var fetchSkillsError: Error?
    var saveSkillError: Error?
    var saveSkillLevelError: Error?
    var deleteSkillError: Error?

    func fetchSkills() async throws -> [Skill] {
        if let fetchSkillsError {
            throw fetchSkillsError
        }

        return remoteSkills
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        if let fetchSkillsError {
            throw fetchSkillsError
        }

        return remoteSkills.first { $0.id == id }
    }

    func saveSkill(_ skill: Skill) async throws {
        if let saveSkillError {
            throw saveSkillError
        }

        savedSkills.append(skill)
    }

    func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill {
        savedLevels.append((skillId: skillId, level: level))

        if let saveSkillLevelError {
            throw saveSkillLevelError
        }

        if !savedLevelResponses.isEmpty {
            let response = savedLevelResponses.removeFirst()
            cacheRemoteSkill(response)
            return response
        }

        guard let skill = remoteSkills.first(where: { $0.id == skillId }) else {
            throw APIError.unsupportedOperation("Skill not found.")
        }

        let response = skill.copy(userLevel: level, syncStatus: .synced)
        cacheRemoteSkill(response)
        return response
    }

    func deleteSkill(id: UUID) async throws {
        if let deleteSkillError {
            throw deleteSkillError
        }

        deletedSkillIDs.append(id)
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        remoteAnimations
    }

    private func cacheRemoteSkill(_ skill: Skill) {
        if let index = remoteSkills.firstIndex(where: { $0.id == skill.id }) {
            remoteSkills[index] = skill
        } else {
            remoteSkills.append(skill)
        }
    }
}

private extension Skill {
    func copy(
        name: String? = nil,
        userLevel: String? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Skill {
        Skill(
            id: id,
            ownerId: ownerId,
            name: name ?? self.name,
            abbreviation: abbreviation,
            description: description,
            category: category,
            difficulty: difficulty,
            animationName: animationName,
            animationType: animationType,
            isSystem: isSystem,
            userLevel: userLevel ?? self.userLevel,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus ?? self.syncStatus,
            steps: steps,
            animationIds: animationIds
        )
    }
}
