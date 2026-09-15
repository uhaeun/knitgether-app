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
    @Published private(set) var statusMessage: String?

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
            statusMessage = nil
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
            statusMessage = "스킬 테스트 결과를 저장했어요."
        }

        return didSave
    }

    @discardableResult
    func savePartialAndExit() async -> Bool {
        let targetSkills = skills.filter { pendingAnswers[$0.id] != nil }
        let didSave = await save(targetSkills)

        if didSave {
            statusMessage = "선택한 스킬 상태를 저장했어요."
        }

        return didSave
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

    func clearStatusMessage() {
        statusMessage = nil
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
            errorMessage = Self.saveErrorMessage(for: error)
            statusMessage = nil
            Self.debugLog("save skill test results failed: \(error)")
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

    /// 저장 실패 문구. 사용자가 취할 수 있는 행동만 남긴다(DEF-28).
    /// 개발 환경 안내(Local Device 설정, Xcode 콘솔, 서버 Terminal 로그)와 상태 코드 숫자는
    /// 최종 사용자가 할 수 있는 조치가 아니라 뺐다. 진단에 필요한 원본 오류는 debugLog가 남긴다.
    private static func saveErrorMessage(for error: Error) -> String {
        if error is URLError {
            return "서버에 연결하지 못했어요. 네트워크 상태를 확인하고 다시 시도해 주세요."
        }

        if let apiError = error as? APIError {
            switch apiError.statusCode {
            case 401:
                return "로그인 정보가 만료됐어요. 다시 로그인해 주세요."
            case 404:
                return "해당 스킬을 찾지 못했어요. 스킬 목록을 새로고침해 주세요."
            default:
                break
            }
        }

        return "스킬 테스트 결과를 저장하지 못했어요."
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[KnitGether SkillTest] \(message)")
        #endif
    }
}
