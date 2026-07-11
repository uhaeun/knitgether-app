import Foundation

final class RemoteDictionaryRepository: DictionaryRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchTerms() async throws -> [DictionaryTerm] {
        try await apiClient.get("dictionary-terms")
    }

    func fetchTerm(id: UUID) async throws -> DictionaryTerm? {
        do {
            return try await apiClient.get("dictionary-terms/\(id.uuidString.lowercased())")
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveTerm(_ term: DictionaryTerm) async throws {
        let body = SaveDictionaryTermRequest(term: term)

        if term.syncStatus == .synced {
            let _: DictionaryTerm = try await apiClient.send(
                "dictionary-terms/\(term.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: DictionaryTerm = try await apiClient.send(
                "dictionary-terms",
                method: "POST",
                body: body
            )
        }
    }

    func deleteTerm(id: UUID) async throws {
        try await apiClient.delete("dictionary-terms/\(id.uuidString.lowercased())")
    }
}

private struct SaveDictionaryTermRequest: Encodable {
    let id: String
    let term: String
    let fullName: String?
    let description: String
    let relatedSkillAbbreviations: String

    init(term: DictionaryTerm) {
        id = term.id.uuidString.lowercased()
        self.term = term.term
        fullName = term.fullName
        description = term.description
        relatedSkillAbbreviations = term.relatedSkillAbbreviations
    }
}
