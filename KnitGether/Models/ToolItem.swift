import Foundation

struct ToolItem: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let type: String
    let link: String?
    let memo: String
    var photoContentType: String? = nil
    var photoByteSize: Int? = nil
    let usageCount: Int
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        name: String,
        type: String,
        link: String? = nil,
        memo: String,
        usageCount: Int = 0,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.type = type
        self.link = link
        self.memo = memo
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        ownerId: String? = nil,
        name: String? = nil,
        type: String? = nil,
        link: String?? = nil,
        memo: String? = nil,
        usageCount: Int? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> ToolItem {
        let resolvedLink: String?
        if let link {
            resolvedLink = link
        } else {
            resolvedLink = self.link
        }

        return ToolItem(
            id: id,
            ownerId: ownerId ?? self.ownerId,
            name: name ?? self.name,
            type: type ?? self.type,
            link: resolvedLink,
            memo: memo ?? self.memo,
            usageCount: usageCount ?? self.usageCount,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}

struct ProjectToolLink: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let toolId: UUID
    let linkedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        toolId: UUID,
        linkedAt: Date,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.toolId = toolId
        self.linkedAt = linkedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        ownerId: String? = nil,
        linkedAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> ProjectToolLink {
        ProjectToolLink(
            id: id,
            ownerId: ownerId ?? self.ownerId,
            projectId: projectId,
            toolId: toolId,
            linkedAt: linkedAt ?? self.linkedAt,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
