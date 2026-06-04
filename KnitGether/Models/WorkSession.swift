//
//  WorkSession.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct WorkSession: Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let startedAt: Date
    let endedAt: Date?
    let memo: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        startedAt: Date,
        endedAt: Date?,
        memo: String?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    var duration: TimeInterval {
        guard let endedAt else {
            return 0
        }

        return endedAt.timeIntervalSince(startedAt)
    }
}
