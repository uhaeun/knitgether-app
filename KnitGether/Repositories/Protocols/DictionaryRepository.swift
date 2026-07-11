import Foundation

protocol DictionaryRepository {
    func fetchTerms() async throws -> [DictionaryTerm]
    func fetchTerm(id: UUID) async throws -> DictionaryTerm?
    func saveTerm(_ term: DictionaryTerm) async throws
    func deleteTerm(id: UUID) async throws
}
