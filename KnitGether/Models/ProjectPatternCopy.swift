//
//  ProjectPatternCopy.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct ProjectPatternCopy: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let sourcePatternDocumentId: UUID?
    let titleSnapshot: String
    let designerSnapshot: String?
    let fileNameSnapshot: String?
    let localCopyPath: String?
    let pageCountSnapshot: Int?
    let drawingDataPath: String?
    let drawingUpdatedAt: Date?
    let copiedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        sourcePatternDocumentId: UUID?,
        titleSnapshot: String,
        designerSnapshot: String?,
        fileNameSnapshot: String?,
        localCopyPath: String?,
        pageCountSnapshot: Int?,
        drawingDataPath: String? = nil,
        drawingUpdatedAt: Date? = nil,
        copiedAt: Date,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.sourcePatternDocumentId = sourcePatternDocumentId
        self.titleSnapshot = titleSnapshot
        self.designerSnapshot = designerSnapshot
        self.fileNameSnapshot = fileNameSnapshot
        self.localCopyPath = localCopyPath
        self.pageCountSnapshot = pageCountSnapshot
        self.drawingDataPath = drawingDataPath
        self.drawingUpdatedAt = drawingUpdatedAt
        self.copiedAt = copiedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func updatingDrawingDataPath(
        _ drawingDataPath: String?,
        at date: Date = Date()
    ) -> ProjectPatternCopy {
        ProjectPatternCopy(
            id: id,
            ownerId: ownerId,
            projectId: projectId,
            sourcePatternDocumentId: sourcePatternDocumentId,
            titleSnapshot: titleSnapshot,
            designerSnapshot: designerSnapshot,
            fileNameSnapshot: fileNameSnapshot,
            localCopyPath: localCopyPath,
            pageCountSnapshot: pageCountSnapshot,
            drawingDataPath: drawingDataPath,
            drawingUpdatedAt: drawingDataPath == nil ? nil : date,
            copiedAt: copiedAt,
            createdAt: createdAt,
            updatedAt: date,
            deletedAt: deletedAt,
            syncStatus: syncStatus
        )
    }
}
