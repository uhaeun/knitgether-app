import Foundation
import Testing
@testable import KnitGether

@MainActor
struct SkillAnimationViewModelTests {
    @Test func loadSkillsFetchesSkillsAndAnimations() async throws {
        let skill = Self.makeSkill(abbreviation: "K")
        let animation = Self.makeAnimation(skillId: skill.id)
        let repository = SkillRepositorySpy(skills: [skill], animations: [animation])
        let viewModel = SkillAnimationViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.skills == [skill])
        #expect(viewModel.skillAnimations == [animation])
        #expect(viewModel.animations(for: skill) == [animation])
    }

    @Test func quickSkillsReturnsUnknownSkillsInCreatedOrder() async throws {
        let known = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            abbreviation: "K",
            difficulty: "기초",
            userLevel: "잘 알아요",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let unknown = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "P",
            difficulty: "기초",
            userLevel: "몰라요",
            createdAt: Date(timeIntervalSince1970: 1_799_000_000)
        )
        let repository = SkillRepositorySpy(skills: [known, unknown])
        let viewModel = SkillAnimationViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.quickSkills(level: "몰라요").map(\.id) == [unknown.id])
    }

    @Test func displayedSkillsAppliesLevelFilterSearchAndSort() async throws {
        let knit = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            abbreviation: "K",
            name: "Knit",
            difficulty: "기초",
            userLevel: "잘 알아요"
        )
        let purl = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "P",
            name: "Purl",
            difficulty: "기초",
            userLevel: "애매해요"
        )
        let repository = SkillRepositorySpy(skills: [purl, knit])
        let viewModel = SkillAnimationViewModel(skillRepository: repository)

        await viewModel.loadSkills()
        viewModel.levelFilter = .unsure
        #expect(viewModel.displayedSkills == [purl])

        viewModel.levelFilter = .all
        viewModel.searchText = "kn"
        #expect(viewModel.displayedSkills == [knit])
    }

    @Test func relatedDictionaryTermsMatchSkillAbbreviation() async throws {
        let skill = Self.makeSkill(abbreviation: "K")
        let directTerm = Self.makeTerm(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            term: "K",
            relatedSkillAbbreviations: ""
        )
        let linkedTerm = Self.makeTerm(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            term: "knit stitch",
            relatedSkillAbbreviations: "P, K"
        )
        let unrelatedTerm = Self.makeTerm(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            term: "YO",
            relatedSkillAbbreviations: "YO"
        )
        let repository = SkillRepositorySpy(skills: [skill])
        let viewModel = SkillAnimationViewModel(skillRepository: repository)

        let related = viewModel.relatedDictionaryTerms(
            for: skill,
            in: [unrelatedTerm, linkedTerm, directTerm]
        )

        #expect(related.map(\.id) == [directTerm.id, linkedTerm.id])
    }

    @Test func frameSequenceUsesSkillStepsForProceduralAnimation() async throws {
        let skill = Self.makeSkill(abbreviation: "K2TOG")
        let viewModel = SkillAnimationViewModel(skillRepository: SkillRepositorySpy(skills: [skill]))

        let sequence = viewModel.frameSequence(for: skill)

        #expect(sequence.title == "K2TOG 기본 프레임")
        #expect(sequence.frames.map(\.instruction) == ["Step 1", "Step 2"])
        #expect(sequence.frames.map(\.activeStitchIndex) == [0, 1])
        #expect(sequence.frames[0].needleAngleDegrees != sequence.frames[1].needleAngleDegrees)
    }

    private static func makeSkill(
        id: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        abbreviation: String,
        name: String? = nil,
        difficulty: String? = "몰라요",
        userLevel: String? = "몰라요",
        createdAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> Skill {
        Skill(
            id: id,
            ownerId: "user-a",
            name: name ?? "\(abbreviation) stitch",
            abbreviation: abbreviation,
            description: "Test skill",
            category: "Basic",
            difficulty: difficulty,
            animationName: "\(abbreviation) animation",
            animationType: "loop",
            isSystem: true,
            userLevel: userLevel,
            createdAt: createdAt,
            updatedAt: createdAt,
            syncStatus: .synced,
            steps: ["Step 1", "Step 2"]
        )
    }

    private static func makeAnimation(skillId: UUID) -> SkillAnimation {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return SkillAnimation(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
            ownerId: "user-a",
            skillId: skillId,
            title: "Knit loop",
            localAssetName: nil,
            durationSeconds: 8,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makeTerm(
        id: UUID,
        term: String,
        relatedSkillAbbreviations: String
    ) -> DictionaryTerm {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return DictionaryTerm(
            id: id,
            ownerId: "user-a",
            term: term,
            fullName: nil,
            description: "\(term) description",
            relatedSkillAbbreviations: relatedSkillAbbreviations,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    final class SkillRepositorySpy: SkillRepository {
        var skills: [Skill]
        var animations: [SkillAnimation]

        init(skills: [Skill] = [], animations: [SkillAnimation] = []) {
            self.skills = skills
            self.animations = animations
        }

        func fetchSkills() async throws -> [Skill] {
            skills
        }

        func fetchSkill(id: UUID) async throws -> Skill? {
            skills.first { $0.id == id }
        }

        func saveSkill(_ skill: Skill) async throws {
            if let index = skills.firstIndex(where: { $0.id == skill.id }) {
                skills[index] = skill
            } else {
                skills.append(skill)
            }
        }

        func deleteSkill(id: UUID) async throws {
            skills.removeAll { $0.id == id }
        }

        func fetchSkillAnimations() async throws -> [SkillAnimation] {
            animations
        }
    }
}
