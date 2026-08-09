//
//  ProjectMaterialLink.swift
//  KnitGether
//
//  LINK-02 v1.4: 실/바늘 다중 연결. 대표(Project.yarnId/needleId)와 별개로
//  추가 연결을 링크 레코드로 관리하며, 표시는 연결 시점 스냅샷을 쓴다(LINK-05).
//

import Foundation

struct ProjectYarnLink: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: String?
    let projectId: UUID
    let yarnId: UUID?
    let nameSnapshot: String
    let brandSnapshot: String?
    let colorwaySnapshot: String?
    let weightSnapshot: String?
    let linkedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        yarnId: UUID?,
        nameSnapshot: String,
        brandSnapshot: String? = nil,
        colorwaySnapshot: String? = nil,
        weightSnapshot: String? = nil,
        linkedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.yarnId = yarnId
        self.nameSnapshot = nameSnapshot
        self.brandSnapshot = brandSnapshot
        self.colorwaySnapshot = colorwaySnapshot
        self.weightSnapshot = weightSnapshot
        self.linkedAt = linkedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    var summaryText: String {
        [
            nameSnapshot,
            brandSnapshot,
            colorwaySnapshot,
            weightSnapshot
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

struct ProjectNeedleLink: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: String?
    let projectId: UUID
    let needleId: UUID?
    let nameSnapshot: String
    let typeSnapshot: String?
    let sizeSnapshot: String?
    let lengthSnapshot: String?
    let linkedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        needleId: UUID?,
        nameSnapshot: String,
        typeSnapshot: String? = nil,
        sizeSnapshot: String? = nil,
        lengthSnapshot: String? = nil,
        linkedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.needleId = needleId
        self.nameSnapshot = nameSnapshot
        self.typeSnapshot = typeSnapshot
        self.sizeSnapshot = sizeSnapshot
        self.lengthSnapshot = lengthSnapshot
        self.linkedAt = linkedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    var summaryText: String {
        [
            nameSnapshot,
            typeSnapshot,
            sizeSnapshot,
            lengthSnapshot
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}
