//
//  ProjectProgressPhoto.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

struct ProjectProgressPhoto: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let fileName: String
    let contentType: String
    let byteSize: Int
    let localFilePath: String?
    let caption: String
    let takenAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        fileName: String,
        contentType: String,
        byteSize: Int,
        localFilePath: String? = nil,
        caption: String,
        takenAt: Date,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.fileName = fileName
        self.contentType = contentType
        self.byteSize = byteSize
        self.localFilePath = localFilePath
        self.caption = caption
        self.takenAt = takenAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }
}
