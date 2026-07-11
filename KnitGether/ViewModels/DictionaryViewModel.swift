import Combine
import Foundation

@MainActor
final class DictionaryViewModel: ObservableObject {
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "전체"
        case abbreviation = "약어"
        case korean = "한글 용어"
        case relatedSkill = "관련 스킬 있음"

        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case defaultOrder = "기본 순서"
        case term = "용어 순"
        case recentUpdated = "최근 수정 순"

        var id: String { rawValue }
    }

    @Published private(set) var terms: [DictionaryTerm] = []
    @Published var searchText = ""
    @Published var filterOption: FilterOption = .all
    @Published var sortOption: SortOption = .defaultOrder
    @Published private(set) var errorMessage: String?

    private let dictionaryRepository: any DictionaryRepository

    init(dictionaryRepository: any DictionaryRepository) {
        self.dictionaryRepository = dictionaryRepository
    }

    var displayedTerms: [DictionaryTerm] {
        sortTerms(filteredTerms(from: terms))
    }

    func loadTerms() async {
        do {
            terms = try await dictionaryRepository.fetchTerms()
            errorMessage = nil
        } catch {
            errorMessage = "뜨개 사전을 불러오지 못했어요."
        }
    }

    func parseRelatedSkillAbbreviations(_ raw: String?) -> [String] {
        skillTags(from: raw ?? "")
    }

    func resolveRelatedSkills(
        for term: DictionaryTerm,
        skills: [Skill]
    ) -> [ResolvedSkillTag] {
        parseRelatedSkillAbbreviations(term.relatedSkillAbbreviations).map { tag in
            let matchedSkill = skills.first { skill in
                skill.abbreviation.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(tag) == .orderedSame
            }

            return ResolvedSkillTag(displayTag: tag, skill: matchedSkill)
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func clearError() {
        errorMessage = nil
    }

    private func filteredTerms(from terms: [DictionaryTerm]) -> [DictionaryTerm] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return terms.filter { term in
            guard matchesFilter(term) else {
                return false
            }

            guard !trimmedSearch.isEmpty else {
                return true
            }

            return term.term.localizedCaseInsensitiveContains(trimmedSearch)
                || term.fullName?.localizedCaseInsensitiveContains(trimmedSearch) == true
                || term.description.localizedCaseInsensitiveContains(trimmedSearch)
                || term.relatedSkillAbbreviations.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private func matchesFilter(_ term: DictionaryTerm) -> Bool {
        switch filterOption {
        case .all:
            return true
        case .abbreviation:
            return term.fullName?.isEmpty == false
        case .korean:
            return term.fullName?.isEmpty != false
        case .relatedSkill:
            return !parseRelatedSkillAbbreviations(term.relatedSkillAbbreviations).isEmpty
        }
    }

    private func sortTerms(_ terms: [DictionaryTerm]) -> [DictionaryTerm] {
        terms.sorted { lhs, rhs in
            switch sortOption {
            case .defaultOrder:
                if lhs.createdAt == rhs.createdAt {
                    return lhs.term.localizedStandardCompare(rhs.term) == .orderedAscending
                }
                return lhs.createdAt < rhs.createdAt
            case .term:
                return lhs.term.localizedStandardCompare(rhs.term) == .orderedAscending
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
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
