import Foundation

struct DictionaryTerm: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let term: String
    let fullName: String?
    let description: String
    let relatedSkillAbbreviations: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        term: String,
        fullName: String? = nil,
        description: String,
        relatedSkillAbbreviations: String = "",
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.term = term
        self.fullName = fullName
        self.description = description
        self.relatedSkillAbbreviations = relatedSkillAbbreviations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        ownerId: String? = nil,
        term: String? = nil,
        fullName: String?? = nil,
        description: String? = nil,
        relatedSkillAbbreviations: String? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> DictionaryTerm {
        let resolvedFullName: String?
        if let fullName {
            resolvedFullName = fullName
        } else {
            resolvedFullName = self.fullName
        }

        return DictionaryTerm(
            id: id,
            ownerId: ownerId ?? self.ownerId,
            term: term ?? self.term,
            fullName: resolvedFullName,
            description: description ?? self.description,
            relatedSkillAbbreviations: relatedSkillAbbreviations ?? self.relatedSkillAbbreviations,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
