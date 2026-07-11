//
//  RowInstruction.swift
//  KnitGether
//
//  Created by Codex on 7/6/26.
//

import Foundation

struct RowInstruction: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let rowCounterId: UUID
    let rowNumber: Int
    let instructionText: String
    let skillTags: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        rowCounterId: UUID,
        rowNumber: Int,
        instructionText: String,
        skillTags: String = "",
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.rowCounterId = rowCounterId
        self.rowNumber = rowNumber
        self.instructionText = instructionText
        self.skillTags = skillTags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }
}
