//
//  RowCounter.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct RowCounter: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let name: String
    let currentRow: Int
    let targetRow: Int?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        name: String = "Main Counter",
        currentRow: Int,
        targetRow: Int?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.name = name
        self.currentRow = currentRow
        self.targetRow = targetRow
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }
}
