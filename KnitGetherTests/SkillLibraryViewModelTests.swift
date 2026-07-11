import Foundation
import Testing
@testable import KnitGether

@MainActor
struct SkillLibraryViewModelTests {
    @Test func formDataInitializesFromExistingSkill() {
        let skill = Self.makeSkill(
            name: "  Knit  ",
            abbreviation: "k",
            description: "  Knit stitch.  ",
            category: "Basics",
            difficulty: "New",
            animationName: "Knit loop",
            animationType: "loop",
            steps: ["Insert needle.", "Wrap yarn."]
        )

        let formData = SkillFormData(skill: skill)

        #expect(formData.name == "  Knit  ")
        #expect(formData.abbreviation == "k")
        #expect(formData.description == "  Knit stitch.  ")
        #expect(formData.category == "Basics")
        #expect(formData.difficulty == "New")
        #expect(formData.animationName == "Knit loop")
        #expect(formData.animationType == "loop")
        #expect(formData.stepsText == "Insert needle.\nWrap yarn.")
    }

    @Test func updateSkillSavesExistingIdentityAndReloadsSkills() async throws {
        let existingSkill = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            ownerId: "user-a",
            name: "Knit",
            abbreviation: "K",
            description: "Knit stitch.",
            category: "기초",
            difficulty: "연습 중",
            syncStatus: .synced
        )
        let repository = FakeSkillRepository(skills: [existingSkill])
        let viewModel = SkillLibraryViewModel(skillRepository: repository)
        var formData = SkillFormData(skill: existingSkill)
        formData.name = "  Purl  "
        formData.abbreviation = " p "
        formData.description = "  Purl stitch.  "
        formData.category = "  Texture  "
        formData.difficulty = "  익숙함  "
        formData.stepsText = "  Insert right needle.\n\nWrap yarn.\nPull through.  "
        formData.animationName = "  Purl motion  "
        formData.animationType = "  loop  "

        let didSave = await viewModel.updateSkill(existingSkill, from: formData)

        #expect(didSave)
        #expect(repository.savedSkills.count == 1)
        #expect(repository.savedSkills[0].id == existingSkill.id)
        #expect(repository.savedSkills[0].ownerId == "user-a")
        #expect(repository.savedSkills[0].name == "Purl")
        #expect(repository.savedSkills[0].abbreviation == "P")
        #expect(repository.savedSkills[0].description == "Purl stitch.")
        #expect(repository.savedSkills[0].category == "Texture")
        #expect(repository.savedSkills[0].difficulty == "익숙함")
        #expect(repository.savedSkills[0].steps == ["Insert right needle.", "Wrap yarn.", "Pull through."])
        #expect(repository.savedSkills[0].animationName == "Purl motion")
        #expect(repository.savedSkills[0].animationType == "loop")
        #expect(repository.savedSkills[0].syncStatus == .synced)
        #expect(viewModel.skills.map(\.name) == ["Purl"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func deleteSkillDeletesAndReloadsSkills() async throws {
        let skill = Self.makeSkill(name: "Knit")
        let repository = FakeSkillRepository(skills: [skill])
        let viewModel = SkillLibraryViewModel(skillRepository: repository)
        await viewModel.loadSkills()

        let didDelete = await viewModel.deleteSkill(skill)

        #expect(didDelete)
        #expect(repository.deletedSkillIDs == [skill.id])
        #expect(viewModel.skills.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func deleteSkillReturnsFalseAndKeepsExistingSkillsWhenDeleteFails() async throws {
        let skill = Self.makeSkill(name: "Knit")
        let repository = FakeSkillRepository(skills: [skill])
        repository.shouldFailDeleteSkill = true
        let viewModel = SkillLibraryViewModel(skillRepository: repository)
        await viewModel.loadSkills()

        let didDelete = await viewModel.deleteSkill(skill)

        #expect(!didDelete)
        #expect(viewModel.skills.map(\.id) == [skill.id])
        #expect(viewModel.errorMessage == "스킬을 삭제하지 못했어요.")
    }

    @Test func systemSkillCannotBeUpdatedOrDeleted() async throws {
        let systemSkill = Self.makeSkill(name: "Knit", isSystem: true)
        let repository = FakeSkillRepository(skills: [systemSkill])
        let viewModel = SkillLibraryViewModel(skillRepository: repository)
        await viewModel.loadSkills()

        var formData = SkillFormData(skill: systemSkill)
        formData.name = "Changed"

        let didUpdate = await viewModel.updateSkill(systemSkill, from: formData)
        let didDelete = await viewModel.deleteSkill(systemSkill)

        #expect(!didUpdate)
        #expect(!didDelete)
        #expect(repository.savedSkills.isEmpty)
        #expect(repository.deletedSkillIDs.isEmpty)
        #expect(viewModel.skills.map(\.id) == [systemSkill.id])
    }

    @Test func retrySyncReloadsSkillsAndClearsPendingStatus() async throws {
        let pendingSkill = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            name: "Knit",
            syncStatus: .pendingUpload
        )
        let syncedSkill = Self.makeSkill(
            id: pendingSkill.id,
            name: "Knit",
            syncStatus: .synced
        )
        let repository = FakeSkillRepository()
        repository.skillFetchResults = [[pendingSkill], [syncedSkill]]
        let viewModel = SkillLibraryViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.hasSkillsNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchSkillsCallCount == 2)
        #expect(viewModel.skills.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasSkillsNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func animationSkillsOnlyIncludesSkillsWithAnimationMetadata() async throws {
        let plainSkill = Self.makeSkill(name: "Purl", abbreviation: "P")
        let animatedSkill = Self.makeSkill(
            name: "Knit",
            abbreviation: "K",
            animationName: "겉뜨기 기본 동작"
        )
        let repository = FakeSkillRepository(skills: [plainSkill, animatedSkill])
        let viewModel = SkillLibraryViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.animationSkills.map(\.name) == ["Knit"])
    }

    @Test func animationSkillsIsEmptyWhenNoSkillsHaveAnimationMetadata() async throws {
        let repository = FakeSkillRepository(skills: [
            Self.makeSkill(name: "Knit", abbreviation: "K"),
            Self.makeSkill(name: "Purl", abbreviation: "P")
        ])
        let viewModel = SkillLibraryViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.animationSkills.isEmpty)
    }

    @Test func animationSkillsIncludesSkillsWithAnimationRecords() async throws {
        let skillID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let animatedSkill = Self.makeSkill(id: skillID, name: "Knit", abbreviation: "K")
        let plainSkill = Self.makeSkill(name: "Purl", abbreviation: "P")
        let repository = FakeSkillRepository(
            skills: [animatedSkill, plainSkill],
            animations: [
                Self.makeAnimation(skillId: skillID, title: "Knit stitch loop")
            ]
        )
        let viewModel = SkillLibraryViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.animationSkills.map(\.name) == ["Knit"])
    }

    @Test func animationsForSkillMatchesAnimationRecordsBySkillIDAndAnimationIDs() async throws {
        let skillID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let animationID = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
        let skill = Self.makeSkill(
            id: skillID,
            name: "Knit",
            abbreviation: "K",
            animationIds: [animationID]
        )
        let repository = FakeSkillRepository(
            skills: [skill],
            animations: [
                Self.makeAnimation(id: animationID, skillId: nil, title: "ID matched"),
                Self.makeAnimation(skillId: skillID, title: "Skill matched"),
                Self.makeAnimation(skillId: UUID(), title: "Other")
            ]
        )
        let viewModel = SkillLibraryViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.animations(for: skill).map(\.title) == ["ID matched", "Skill matched"])
    }

    private static func makeSkill(
        id: UUID = UUID(),
        ownerId: String? = "user-a",
        name: String,
        abbreviation: String = "K",
        description: String = "Knit stitch.",
        category: String? = nil,
        difficulty: String? = nil,
        animationName: String? = nil,
        animationType: String? = nil,
        steps: [String] = [],
        animationIds: [UUID] = [],
        isSystem: Bool = false,
        userLevel: String? = nil,
        syncStatus: SyncStatus = .synced
    ) -> Skill {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Skill(
            id: id,
            ownerId: ownerId,
            name: name,
            abbreviation: abbreviation,
            description: description,
            category: category,
            difficulty: difficulty,
            animationName: animationName,
            animationType: animationType,
            isSystem: isSystem,
            userLevel: userLevel,
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus,
            steps: steps,
            animationIds: animationIds
        )
    }

    private static func makeAnimation(
        id: UUID = UUID(),
        skillId: UUID?,
        title: String
    ) -> SkillAnimation {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return SkillAnimation(
            id: id,
            ownerId: "user-a",
            skillId: skillId,
            title: title,
            localAssetName: nil,
            durationSeconds: nil,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }
}

@MainActor
private final class FakeSkillRepository: SkillRepository {
    private var skills: [Skill]
    private var animations: [SkillAnimation]
    var skillFetchResults: [[Skill]] = []
    var fetchSkillsCallCount = 0
    var savedSkills: [Skill] = []
    var deletedSkillIDs: [UUID] = []
    var shouldFailDeleteSkill = false

    init(
        skills: [Skill] = [],
        animations: [SkillAnimation] = []
    ) {
        self.skills = skills
        self.animations = animations
    }

    func fetchSkills() async throws -> [Skill] {
        fetchSkillsCallCount += 1

        if !skillFetchResults.isEmpty {
            skills = skillFetchResults.removeFirst()
        }

        return skills
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        skills.first { $0.id == id }
    }

    func saveSkill(_ skill: Skill) async throws {
        savedSkills.append(skill)
        if let index = skills.firstIndex(where: { $0.id == skill.id }) {
            skills[index] = skill
        } else {
            skills.append(skill)
        }
    }

    func deleteSkill(id: UUID) async throws {
        if shouldFailDeleteSkill {
            throw URLError(.cannotConnectToHost)
        }

        deletedSkillIDs.append(id)
        skills.removeAll { $0.id == id }
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        animations
    }
}
