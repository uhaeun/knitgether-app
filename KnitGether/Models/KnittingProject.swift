//
//  KnittingProject.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

struct KnittingProject: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let status: ProjectStatus
    let isFavorite: Bool
    let memo: String
    let startDate: Date
    let lastWorkedAt: Date?
    let patternCopy: ProjectPatternCopy?
    let workspaceDisplayMode: ProjectWorkspaceDisplayMode?
    let workspaceSheetPosition: ProjectWorkspaceSheetPosition?
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
        workspaceDisplayMode: ProjectWorkspaceDisplayMode? = .patternAndCounter,
        workspaceSheetPosition: ProjectWorkspaceSheetPosition? = .medium,
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
        self.workspaceDisplayMode = workspaceDisplayMode
        self.workspaceSheetPosition = workspaceSheetPosition
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

    func updatingRow(to row: Int, at date: Date = Date()) -> KnittingProject {
        let updatedCounter = RowCounter(
            id: rowCounter.id,
            ownerId: rowCounter.ownerId,
            projectId: rowCounter.projectId,
            name: rowCounter.name,
            currentRow: max(0, row),
            targetRow: rowCounter.targetRow,
            createdAt: rowCounter.createdAt,
            updatedAt: date,
            deletedAt: rowCounter.deletedAt,
            syncStatus: rowCounter.syncStatus
        )

        return copy(
            lastWorkedAt: date,
            rowCounter: updatedCounter,
            updatedAt: date
        )
    }

    func updatingMemo(to memo: String, at date: Date = Date()) -> KnittingProject {
        copy(
            memo: memo,
            updatedAt: date
        )
    }

    func recordingWorkSession(
        startedAt: Date,
        endedAt: Date,
        memo: String? = nil
    ) -> KnittingProject {
        let session = WorkSession(
            ownerId: ownerId,
            projectId: id,
            startedAt: startedAt,
            endedAt: endedAt,
            memo: memo,
            createdAt: endedAt,
            updatedAt: endedAt,
            syncStatus: syncStatus
        )

        return copy(
            lastWorkedAt: endedAt,
            workSessions: workSessions + [session],
            updatedAt: endedAt
        )
    }

    func copy(
        name: String? = nil,
        status: ProjectStatus? = nil,
        isFavorite: Bool? = nil,
        memo: String? = nil,
        startDate: Date? = nil,
        lastWorkedAt: Date? = nil,
        patternCopy: ProjectPatternCopy? = nil,
        workspaceDisplayMode: ProjectWorkspaceDisplayMode? = nil,
        workspaceSheetPosition: ProjectWorkspaceSheetPosition? = nil,
        rowCounter: RowCounter? = nil,
        workSessions: [WorkSession]? = nil,
        relatedSkillIds: [UUID]? = nil,
        updatedAt: Date = Date()
    ) -> KnittingProject {
        KnittingProject(
            id: id,
            ownerId: ownerId,
            name: name ?? self.name,
            status: status ?? self.status,
            isFavorite: isFavorite ?? self.isFavorite,
            memo: memo ?? self.memo,
            startDate: startDate ?? self.startDate,
            lastWorkedAt: lastWorkedAt ?? self.lastWorkedAt,
            patternCopy: patternCopy ?? self.patternCopy,
            workspaceDisplayMode: workspaceDisplayMode ?? self.workspaceDisplayMode,
            workspaceSheetPosition: workspaceSheetPosition ?? self.workspaceSheetPosition,
            rowCounter: rowCounter ?? self.rowCounter,
            workSessions: workSessions ?? self.workSessions,
            relatedSkillIds: relatedSkillIds ?? self.relatedSkillIds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus
        )
    }
}
