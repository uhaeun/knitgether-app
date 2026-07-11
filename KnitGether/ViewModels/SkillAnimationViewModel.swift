import Combine
import Foundation

@MainActor
final class SkillAnimationViewModel: ObservableObject {
    enum LevelFilter: String, CaseIterable, Identifiable {
        case all = "전체"
        case unknown = "몰라요"
        case unsure = "헷갈려요"
        case known = "잘 알아요"

        var id: String { rawValue }

        var levelValue: String? {
            self == .all ? nil : rawValue
        }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case defaultOrder = "기본 순서"
        case abbreviation = "약어 순"
        case name = "이름 순"
        case level = "이해도 순"
        case recentUpdated = "최근 수정 순"

        var id: String { rawValue }
    }

    @Published private(set) var skills: [Skill] = []
    @Published private(set) var skillAnimations: [SkillAnimation] = []
    @Published var searchText = ""
    @Published var levelFilter: LevelFilter = .all
    @Published var sortOption: SortOption = .defaultOrder
    @Published private(set) var errorMessage: String?

    private let skillRepository: any SkillRepository

    init(skillRepository: any SkillRepository) {
        self.skillRepository = skillRepository
    }

    var displayedSkills: [Skill] {
        sortSkills(filteredSkills(skills))
    }

    func loadSkills() async {
        do {
            skills = try await skillRepository.fetchSkills()
            skillAnimations = try await skillRepository.fetchSkillAnimations()
            errorMessage = nil
        } catch {
            errorMessage = "뜨개 애니메이션을 불러오지 못했어요."
        }
    }

    func quickSkills(level: String, limit: Int = 5) -> [Skill] {
        skills
            .filter { levelDisplayName($0.userLevel) == level }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.abbreviation.localizedStandardCompare(rhs.abbreviation) == .orderedAscending
                }
                return lhs.createdAt < rhs.createdAt
            }
            .prefix(limit)
            .map { $0 }
    }

    func animations(for skill: Skill) -> [SkillAnimation] {
        skillAnimations.filter { animation in
            animation.skillId == skill.id || skill.animationIds.contains(animation.id)
        }
    }

    func stepDescriptions(for skill: Skill) -> [String] {
        if !skill.steps.isEmpty {
            return skill.steps
        }
        return Self.stepsForAbbreviation(skill.abbreviation)
    }

    func frameSequence(for skill: Skill) -> SkillAnimationFrameSequence {
        SkillAnimationFrameSequence.make(
            abbreviation: skill.abbreviation,
            steps: stepDescriptions(for: skill)
        )
    }

    func relatedDictionaryTerms(
        for skill: Skill,
        in terms: [DictionaryTerm]
    ) -> [DictionaryTerm] {
        let abbreviation = skill.abbreviation
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !abbreviation.isEmpty else {
            return []
        }

        return terms
            .filter { term in
                term.term
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == abbreviation
                    || skillTags(from: term.relatedSkillAbbreviations).contains(abbreviation)
            }
            .sorted { lhs, rhs in
                let lhsIsDirect = lhs.term.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(skill.abbreviation) == .orderedSame
                let rhsIsDirect = rhs.term.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(skill.abbreviation) == .orderedSame

                if lhsIsDirect != rhsIsDirect {
                    return lhsIsDirect
                }

                return lhs.term.localizedStandardCompare(rhs.term) == .orderedAscending
            }
    }

    @discardableResult
    func updateSkillLevel(_ skill: Skill, level: String) async -> Bool {
        do {
            let updatedSkill = try await skillRepository.saveSkillLevel(
                skillId: skill.id,
                level: levelDisplayName(level)
            )
            if let index = skills.firstIndex(where: { $0.id == skill.id }) {
                skills[index] = updatedSkill
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "스킬 이해도를 저장하지 못했어요."
            return false
        }
    }

    func levelDisplayName(_ level: String?) -> String {
        SkillLevelFormatter.normalizedLevel(level)
    }

    func clearError() {
        errorMessage = nil
    }

    static func stepsForAbbreviation(_ abbreviation: String) -> [String] {
        switch abbreviation.lowercased() {
        case "co":
            return ["바늘과 실을 준비해요.", "도안에서 요구하는 코 수만큼 코를 잡아요.", "코가 너무 조이거나 느슨하지 않게 균일하게 잡아요."]
        case "bo":
            return ["첫 코와 다음 코를 뜬 뒤, 앞의 코를 뒤의 코 위로 넘겨요.", "이 과정을 반복하며 코를 마무리해요.", "마지막 코는 실을 빼서 단단히 정리해요."]
        case "k":
            return ["오른쪽 바늘을 왼쪽 바늘의 앞쪽에서 코에 넣어요.", "실을 감아 코를 통과시켜요.", "새 코를 오른쪽 바늘로 옮겨요."]
        case "p":
            return ["실을 바늘 앞쪽에 둬요.", "오른쪽 바늘을 코의 앞쪽에서 넣어요.", "실을 감아 새 코를 만들고 오른쪽 바늘로 옮겨요."]
        case "yo":
            return ["바늘에 실을 한 번 감아요.", "다음 코를 뜨면 감긴 실이 새 코가 돼요.", "구멍무늬나 코 늘림에 자주 사용돼요."]
        case "k2tog":
            return ["두 코를 한 번에 오른쪽 바늘로 넣어요.", "두 코를 함께 겉뜨기해요.", "오른쪽으로 기울어진 줄임이 생겨요."]
        case "ssk":
            return ["두 코를 차례로 오른쪽 바늘에 겉뜨기 방향으로 넘겨요.", "넘긴 두 코를 다시 왼쪽 바늘에 옮겨요.", "두 코를 함께 겉뜨기해 왼쪽으로 기울어진 줄임을 만들어요."]
        default:
            return ["이 스킬의 단계별 설명은 준비 중이에요. 우선 스킬 설명을 참고해주세요."]
        }
    }

    private func filteredSkills(_ skills: [Skill]) -> [Skill] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return skills.filter { skill in
            if let targetLevel = levelFilter.levelValue,
               levelDisplayName(skill.userLevel) != targetLevel {
                return false
            }

            guard !trimmedSearch.isEmpty else {
                return true
            }

            return skill.abbreviation.localizedCaseInsensitiveContains(trimmedSearch)
                || skill.name.localizedCaseInsensitiveContains(trimmedSearch)
                || skill.description.localizedCaseInsensitiveContains(trimmedSearch)
                || skill.category?.localizedCaseInsensitiveContains(trimmedSearch) == true
        }
    }

    private func sortSkills(_ skills: [Skill]) -> [Skill] {
        skills.sorted { lhs, rhs in
            switch sortOption {
            case .defaultOrder:
                if lhs.createdAt == rhs.createdAt {
                    return lhs.abbreviation.localizedStandardCompare(rhs.abbreviation) == .orderedAscending
                }
                return lhs.createdAt < rhs.createdAt
            case .abbreviation:
                return lhs.abbreviation.localizedStandardCompare(rhs.abbreviation) == .orderedAscending
            case .name:
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .level:
                let lhsPriority = SkillLevelFormatter.levelPriority(lhs.userLevel)
                let rhsPriority = SkillLevelFormatter.levelPriority(rhs.userLevel)
                if lhsPriority == rhsPriority {
                    return lhs.abbreviation.localizedStandardCompare(rhs.abbreviation) == .orderedAscending
                }
                return lhsPriority < rhsPriority
            case .recentUpdated:
                return lhs.updatedAt > rhs.updatedAt
            }
        }
    }

    private func skillTags(from input: String) -> [String] {
        input
            .split { character in
                character == "," || character == " " || character == "\n"
            }
            .map {
                $0
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }
    }
}
