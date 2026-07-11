import Foundation
import Testing
@testable import KnitGether

@MainActor
struct DictionaryViewModelTests {
    @Test func loadTermsSortsDefaultOrderAndSearchesAcrossFields() async throws {
        let older = Self.makeTerm(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            term: "K",
            fullName: "Knit",
            description: "Basic knit stitch.",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let newer = Self.makeTerm(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            term: "YO",
            fullName: "Yarn over",
            description: "Makes an eyelet.",
            relatedSkillAbbreviations: "YO",
            createdAt: Date(timeIntervalSince1970: 1_800_010_000)
        )
        let repository = DictionaryRepositorySpy(terms: [newer, older])
        let viewModel = DictionaryViewModel(dictionaryRepository: repository)

        await viewModel.loadTerms()
        #expect(viewModel.displayedTerms.map(\.id) == [older.id, newer.id])

        viewModel.searchText = "eyelet"
        #expect(viewModel.displayedTerms.map(\.id) == [newer.id])
    }

    @Test func filterOptionsSeparateAbbreviationKoreanAndRelatedSkillTerms() async throws {
        let abbreviation = Self.makeTerm(
            term: "K2TOG",
            fullName: "Knit two together",
            description: "Decrease.",
            relatedSkillAbbreviations: "K,K2TOG"
        )
        let korean = Self.makeTerm(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            term: "겉뜨기",
            fullName: nil,
            description: "기본 뜨기."
        )
        let repository = DictionaryRepositorySpy(terms: [abbreviation, korean])
        let viewModel = DictionaryViewModel(dictionaryRepository: repository)

        await viewModel.loadTerms()

        viewModel.filterOption = .abbreviation
        #expect(viewModel.displayedTerms == [abbreviation])

        viewModel.filterOption = .korean
        #expect(viewModel.displayedTerms == [korean])

        viewModel.filterOption = .relatedSkill
        #expect(viewModel.displayedTerms == [abbreviation])
    }

    @Test func resolveRelatedSkillsMatchesRegisteredAndUnregisteredTags() async throws {
        let term = Self.makeTerm(relatedSkillAbbreviations: "K, YO")
        let skill = Self.makeSkill(abbreviation: "K")
        let viewModel = DictionaryViewModel(dictionaryRepository: DictionaryRepositorySpy())

        let resolvedTags = viewModel.resolveRelatedSkills(for: term, skills: [skill])

        #expect(resolvedTags.map(\.displayTag) == ["K", "YO"])
        #expect(resolvedTags[0].skill?.id == skill.id)
        #expect(resolvedTags[0].isRegistered)
        #expect(!resolvedTags[1].isRegistered)
    }

    private static func makeTerm(
        id: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        term: String = "K2TOG",
        fullName: String? = "Knit two together",
        description: String = "Two stitches are knit together.",
        relatedSkillAbbreviations: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> DictionaryTerm {
        DictionaryTerm(
            id: id,
            ownerId: "user-a",
            term: term,
            fullName: fullName,
            description: description,
            relatedSkillAbbreviations: relatedSkillAbbreviations,
            createdAt: createdAt,
            updatedAt: createdAt,
            syncStatus: .synced
        )
    }

    private static func makeSkill(abbreviation: String) -> Skill {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return Skill(
            ownerId: "user-a",
            name: "\(abbreviation) stitch",
            abbreviation: abbreviation,
            description: "Test skill",
            difficulty: "잘 알아요",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    final class DictionaryRepositorySpy: DictionaryRepository {
        var terms: [DictionaryTerm]
        var savedTerms: [DictionaryTerm] = []
        var deletedTermIDs: [UUID] = []

        init(terms: [DictionaryTerm] = []) {
            self.terms = terms
        }

        func fetchTerms() async throws -> [DictionaryTerm] {
            terms
        }

        func fetchTerm(id: UUID) async throws -> DictionaryTerm? {
            terms.first { $0.id == id }
        }

        func saveTerm(_ term: DictionaryTerm) async throws {
            savedTerms.append(term)
            if let index = terms.firstIndex(where: { $0.id == term.id }) {
                terms[index] = term
            } else {
                terms.append(term)
            }
        }

        func deleteTerm(id: UUID) async throws {
            deletedTermIDs.append(id)
            terms.removeAll { $0.id == id }
        }
    }
}
