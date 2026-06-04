//
//  KnittingProject.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

struct KnittingProject: Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let status: ProjectStatus
    let isFavorite: Bool
    let memo: String
    let startDate: Date
    let lastWorkedAt: Date?
    let patternCopy: ProjectPatternCopy?
    let rowCounter: RowCounter
    let workSessions: [WorkSession]
    let relatedSkillIds: [UUID]
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        name: String,
        status: ProjectStatus,
        isFavorite: Bool,
        memo: String,
        startDate: Date,
        lastWorkedAt: Date?,
        patternCopy: ProjectPatternCopy?,
        rowCounter: RowCounter,
        workSessions: [WorkSession],
        relatedSkillIds: [UUID] = [],
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.status = status
        self.isFavorite = isFavorite
        self.memo = memo
        self.startDate = startDate
        self.lastWorkedAt = lastWorkedAt
        self.patternCopy = patternCopy
        self.rowCounter = rowCounter
        self.workSessions = workSessions
        self.relatedSkillIds = relatedSkillIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    var totalWorkTime: TimeInterval {
        workSessions.reduce(0) { total, session in
            total + session.duration
        }
    }

    var hasPatternAttached: Bool {
        patternCopy != nil
    }
}
