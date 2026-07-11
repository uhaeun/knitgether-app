//
//  ProjectYarnUsage.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

struct ProjectYarnUsage: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: String?
    let projectId: UUID
    let projectNameSnapshot: String?
    let yarnId: UUID
    let yarnNameSnapshot: String
    let quantityUsed: Int
    let memo: String
    let usedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        projectNameSnapshot: String? = nil,
        yarnId: UUID,
        yarnNameSnapshot: String,
        quantityUsed: Int,
        memo: String = "",
        usedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.projectNameSnapshot = projectNameSnapshot
        self.yarnId = yarnId
        self.yarnNameSnapshot = yarnNameSnapshot
        self.quantityUsed = quantityUsed
        self.memo = memo
        self.usedAt = usedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        projectNameSnapshot: String? = nil,
        memo: String? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> ProjectYarnUsage {
        ProjectYarnUsage(
            id: id,
            ownerId: ownerId,
            projectId: projectId,
            projectNameSnapshot: projectNameSnapshot ?? self.projectNameSnapshot,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            quantityUsed: quantityUsed,
            memo: memo ?? self.memo,
            usedAt: usedAt,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
