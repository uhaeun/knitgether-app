//
//  PatternDocument.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct PatternDocument: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let title: String
    let designer: String?
    let fileName: String?
    let localFilePath: String?
    let pageCount: Int?
    let notes: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        title: String,
        designer: String?,
        fileName: String?,
        localFilePath: String?,
        pageCount: Int?,
        notes: String,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.designer = designer
        self.fileName = fileName
        self.localFilePath = localFilePath
        self.pageCount = pageCount
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        title: String? = nil,
        designer: String? = nil,
        fileName: String? = nil,
        localFilePath: String? = nil,
        pageCount: Int? = nil,
        notes: String? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> PatternDocument {
        PatternDocument(
            id: id,
            ownerId: ownerId,
            title: title ?? self.title,
            designer: designer ?? self.designer,
            fileName: fileName ?? self.fileName,
            localFilePath: localFilePath ?? self.localFilePath,
            pageCount: pageCount ?? self.pageCount,
            notes: notes ?? self.notes,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
