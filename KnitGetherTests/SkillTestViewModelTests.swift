import Foundation
import Testing
@testable import KnitGether

@MainActor
struct SkillTestViewModelTests {
    @Test func skillLevelFormatterUsesTrafficLightLabelsAndAcceptsLegacyUnsureText() async throws {
        #expect(SkillLevelFormatter.levels == ["몰라요", "헷갈려요", "잘 알아요"])
        #expect(SkillLevelFormatter.normalizedLevel("애매해요") == "헷갈려요")
    }

    @Test func loadSkillsSortsByCreatedAtThenAbbreviation() async throws {
        let laterSkill = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            abbreviation: "P",
            createdAt: Date(timeIntervalSince1970: 1_800_010_000)
        )
        let firstSkill = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "CO",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let secondSkill = Self.makeSkill(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            abbreviation: "K",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let repository = SkillRepositorySpy(skills: [laterSkill, secondSkill, firstSkill])
        let viewModel = SkillTestViewModel(skillRepository: repository)

        await viewModel.loadSkills()

        #expect(viewModel.skills.map(\.abbreviation) == ["CO", "K", "P"])
        #expect(viewModel.progressText == "1 / 3")
        #expect(viewModel.progressValue == 1.0 / 3.0)
    }

    @Test func selectingLevelsAndSavingResultsPersistsAllSkillsAndBuildsSummary() async throws {
        let unknownSkill = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            abbreviation: "CO",
            difficulty: "초급",
            userLevel: nil
        )
        let unsureSkill = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "K",
            difficulty: "기초",
            userLevel: "몰라요"
        )
        let knownSkill = Self.makeSkill(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            abbreviation: "P",
            difficulty: "기초",
            userLevel: "몰라요"
        )
        let repository = SkillRepositorySpy(skills: [unknownSkill, unsureSkill, knownSkill])
        let viewModel = SkillTestViewModel(skillRepository: repository)

        await viewModel.loadSkills()
        viewModel.selectLevel("몰라요", for: unknownSkill)
        viewModel.selectLevel("헷갈려요", for: unsureSkill)
        viewModel.selectLevel("잘 알아요", for: knownSkill)

        let didSave = await viewModel.saveResults()

        #expect(didSave)
        #expect(repository.savedLevels.map(\.level) == ["몰라요", "헷갈려요", "잘 알아요"])
        #expect(viewModel.skills.map(\.userLevel) == ["몰라요", "헷갈려요", "잘 알아요"])
        #expect(viewModel.isCompleted)
        #expect(viewModel.resultSummary?.totalCount == 3)
        #expect(viewModel.resultSummary?.unknownCount == 1)
        #expect(viewModel.resultSummary?.unsureCount == 1)
        #expect(viewModel.resultSummary?.knownCount == 1)
    }

    @Test func savePartialAndExitPersistsOnlyAnsweredSkills() async throws {
        let firstSkill = Self.makeSkill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            abbreviation: "CO",
            difficulty: "기초",
            userLevel: "몰라요"
        )
        let secondSkill = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "K",
            difficulty: "기초",
            userLevel: "몰라요"
        )
        let repository = SkillRepositorySpy(skills: [firstSkill, secondSkill])
        let viewModel = SkillTestViewModel(skillRepository: repository)

        await viewModel.loadSkills()
        viewModel.selectLevel("잘 알아요", for: secondSkill)

        let didSave = await viewModel.savePartialAndExit()

        #expect(didSave)
        #expect(repository.savedLevels.map(\.skillId) == [secondSkill.id])
        #expect(repository.savedLevels.map(\.level) == ["잘 알아요"])
        #expect(!viewModel.isCompleted)
    }

    @Test func navigationClampsToValidSkillRange() async throws {
        let firstSkill = Self.makeSkill(abbreviation: "CO")
        let secondSkill = Self.makeSkill(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            abbreviation: "K"
        )
        let repository = SkillRepositorySpy(skills: [firstSkill, secondSkill])
        let viewModel = SkillTestViewModel(skillRepository: repository)

        await viewModel.loadSkills()
        viewModel.goPrevious()
        #expect(viewModel.currentIndex == 0)

        viewModel.goNext()
        viewModel.goNext()
        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.isLastSkill)

        repository.skills = [firstSkill]
        await viewModel.loadSkills()
        #expect(viewModel.currentIndex == 0)
    }

    private static func makeSkill(
        id: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        abbreviation: String,
        difficulty: String? = "몰라요",
        userLevel: String? = "몰라요",
        createdAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> Skill {
        Skill(
            id: id,
            ownerId: "user-a",
            name: "\(abbreviation) stitch",
            abbreviation: abbreviation,
            description: "Test skill",
            category: "Basic",
            difficulty: difficulty,
            isSystem: true,
            userLevel: userLevel,
            createdAt: createdAt,
            updatedAt: createdAt,
            syncStatus: .synced
        )
    }

    final class SkillRepositorySpy: SkillRepository {
        var skills: [Skill]
        var savedSkills: [Skill] = []
        var savedLevels: [(skillId: UUID, level: String)] = []

        init(skills: [Skill]) {
            self.skills = skills
        }

        func fetchSkills() async throws -> [Skill] {
            skills
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

        func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill {
            savedLevels.append((skillId: skillId, level: level))
            guard let index = skills.firstIndex(where: { $0.id == skillId }) else {
                throw APIError.unsupportedOperation("Skill not found.")
            }

            let updatedSkill = skills[index].updatingUserLevel(
                level,
                updatedAt: Date(),
                syncStatus: .synced
            )
            skills[index] = updatedSkill
            return updatedSkill
        }

        func deleteSkill(id: UUID) async throws {
            skills.removeAll { $0.id == id }
        }

        func fetchSkillAnimations() async throws -> [SkillAnimation] {
            []
        }
    }
}
