import Combine
import Foundation

struct SkillTestResultSummary {
    let totalCount: Int
    let unknownCount: Int
    let unsureCount: Int
    let knownCount: Int

    var dominantLevelText: String {
        let pairs = [
            (SkillLevelFormatter.unknown, unknownCount),
            (SkillLevelFormatter.unsure, unsureCount),
            (SkillLevelFormatter.known, knownCount),
        ]
        return pairs.max { lhs, rhs in
            lhs.1 < rhs.1
        }?.0 ?? SkillLevelFormatter.unknown
    }
}

@MainActor
final class SkillTestViewModel: ObservableObject {
    struct LevelOption: Identifiable {
        let id: String
        let name: String
    }

    @Published private(set) var skills: [Skill] = []
    @Published var currentIndex = 0
    @Published var pendingAnswers: [UUID: String] = [:]
    @Published private(set) var isCompleted = false
    @Published private(set) var resultSummary: SkillTestResultSummary?
    @Published private(set) var errorMessage: String?

    let levelOptions: [LevelOption] = SkillLevelFormatter.levels.map {
        LevelOption(id: $0, name: $0)
    }

    private let skillRepository: any SkillRepository

    init(skillRepository: any SkillRepository) {
        self.skillRepository = skillRepository
    }

    var currentSkill: Skill? {
        guard skills.indices.contains(currentIndex) else {
            return nil
        }
        return skills[currentIndex]
    }

    var canGoPrevious: Bool {
        currentIndex > 0
    }

    var isLastSkill: Bool {
        !skills.isEmpty && currentIndex == skills.count - 1
    }

    var progressText: String {
        guard !skills.isEmpty else {
            return "0 / 0"
        }
        return "\(currentIndex + 1) / \(skills.count)"
    }

    var progressValue: Double {
        guard !skills.isEmpty else {
            return 0
        }
        return Double(currentIndex + 1) / Double(skills.count)
    }

    func loadSkills() async {
        do {
            skills = Self.sortedSkills(try await skillRepository.fetchSkills())
            clampCurrentIndex()
            errorMessage = nil
        } catch {
            errorMessage = "스킬 테스트 목록을 불러오지 못했어요."
        }
    }

    func selectLevel(_ level: String, for skill: Skill) {
        pendingAnswers[skill.id] = levelDisplayName(level)
    }

    func selectedLevel(for skill: Skill) -> String {
        pendingAnswers[skill.id] ?? levelDisplayName(skill.userLevel)
    }

    func goNext() {
        guard currentIndex < skills.count - 1 else {
            return
        }
        currentIndex += 1
    }

    func goPrevious() {
        guard currentIndex > 0 else {
            return
        }
        currentIndex -= 1
    }

    @discardableResult
    func saveResults() async -> Bool {
        let targetSkills = skills
        let didSave = await save(targetSkills)

        if didSave {
            resultSummary = summary(from: skills)
            isCompleted = true
        }

        return didSave
    }

    @discardableResult
    func savePartialAndExit() async -> Bool {
        let targetSkills = skills.filter { pendingAnswers[$0.id] != nil }
        return await save(targetSkills)
    }

    func summary(from skills: [Skill]) -> SkillTestResultSummary {
        SkillTestResultSummary(
            totalCount: skills.count,
            unknownCount: skills.filter { selectedLevel(for: $0) == SkillLevelFormatter.unknown }.count,
            unsureCount: skills.filter { selectedLevel(for: $0) == SkillLevelFormatter.unsure }.count,
            knownCount: skills.filter { selectedLevel(for: $0) == SkillLevelFormatter.known }.count
        )
    }

    func clampCurrentIndex() {
        guard !skills.isEmpty else {
            currentIndex = 0
            return
        }
        currentIndex = min(max(0, currentIndex), skills.count - 1)
    }

    func levelDisplayName(_ level: String?) -> String {
        SkillLevelFormatter.normalizedLevel(level)
    }

    func clearError() {
        errorMessage = nil
    }

    private func save(_ targetSkills: [Skill]) async -> Bool {
        var updatedSkillsByID: [UUID: Skill] = [:]

        do {
            for skill in targetSkills {
                let updatedSkill = try await skillRepository.saveSkillLevel(
                    skillId: skill.id,
                    level: selectedLevel(for: skill)
                )
                updatedSkillsByID[updatedSkill.id] = updatedSkill
            }

            if !updatedSkillsByID.isEmpty {
                skills = skills.map { updatedSkillsByID[$0.id] ?? $0 }
            }

            errorMessage = nil
            return true
        } catch {
            errorMessage = "스킬 테스트 결과를 저장하지 못했어요."
            return false
        }
    }

    private static func sortedSkills(_ skills: [Skill]) -> [Skill] {
        skills.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.abbreviation.localizedStandardCompare(rhs.abbreviation) == .orderedAscending
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
}
