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
    let targetDate: Date?
    let finishedAt: Date?
    let lastWorkedAt: Date?
    let patternCopy: ProjectPatternCopy?
    let yarnId: UUID?
    let yarnNameSnapshot: String?
    let yarnBrandSnapshot: String?
    let yarnColorwaySnapshot: String?
    let yarnWeightSnapshot: String?
    let needleId: UUID?
    let needleNameSnapshot: String?
    let needleTypeSnapshot: String?
    let needleSizeSnapshot: String?
    let needleLengthSnapshot: String?
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
        targetDate: Date? = nil,
        finishedAt: Date? = nil,
        lastWorkedAt: Date?,
        patternCopy: ProjectPatternCopy?,
        yarnId: UUID? = nil,
        yarnNameSnapshot: String? = nil,
        yarnBrandSnapshot: String? = nil,
        yarnColorwaySnapshot: String? = nil,
        yarnWeightSnapshot: String? = nil,
        needleId: UUID? = nil,
        needleNameSnapshot: String? = nil,
        needleTypeSnapshot: String? = nil,
        needleSizeSnapshot: String? = nil,
        needleLengthSnapshot: String? = nil,
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
        self.targetDate = targetDate
        self.finishedAt = finishedAt
        self.lastWorkedAt = lastWorkedAt
        self.patternCopy = patternCopy
        self.yarnId = yarnId
        self.yarnNameSnapshot = yarnNameSnapshot
        self.yarnBrandSnapshot = yarnBrandSnapshot
        self.yarnColorwaySnapshot = yarnColorwaySnapshot
        self.yarnWeightSnapshot = yarnWeightSnapshot
        self.needleId = needleId
        self.needleNameSnapshot = needleNameSnapshot
        self.needleTypeSnapshot = needleTypeSnapshot
        self.needleSizeSnapshot = needleSizeSnapshot
        self.needleLengthSnapshot = needleLengthSnapshot
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

    var hasMaterialsAttached: Bool {
        yarnSummaryText != nil || needleSummaryText != nil
    }

    var yarnSummaryText: String? {
        [
            yarnNameSnapshot,
            yarnBrandSnapshot,
            yarnColorwaySnapshot,
            yarnWeightSnapshot
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
        .nilIfEmpty
    }

    var needleSummaryText: String? {
        [
            needleNameSnapshot,
            needleTypeSnapshot,
            needleSizeSnapshot,
            needleLengthSnapshot
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
        .nilIfEmpty
    }

    var materialSummaryText: String {
        [
            yarnSummaryText.map { "실 \($0)" },
            needleSummaryText.map { "바늘 \($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: " / ")
        .nilIfEmpty ?? "재료 미연결"
    }

    func daysUntilTarget(
        from referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let targetDate else {
            return nil
        }

        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    func updatingRow(to row: Int, at date: Date = Date()) -> KnittingProject {
        let updatedCounter = rowCounter.copy(
            currentRow: max(0, row),
            updatedAt: date
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

    func replacingPatternCopy(
        with patternCopy: ProjectPatternCopy?,
        at date: Date = Date()
    ) -> KnittingProject {
        KnittingProject(
            id: id,
            ownerId: ownerId,
            name: name,
            status: status,
            isFavorite: isFavorite,
            memo: memo,
            startDate: startDate,
            targetDate: targetDate,
            finishedAt: finishedAt,
            lastWorkedAt: lastWorkedAt,
            patternCopy: patternCopy,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            yarnBrandSnapshot: yarnBrandSnapshot,
            yarnColorwaySnapshot: yarnColorwaySnapshot,
            yarnWeightSnapshot: yarnWeightSnapshot,
            needleId: needleId,
            needleNameSnapshot: needleNameSnapshot,
            needleTypeSnapshot: needleTypeSnapshot,
            needleSizeSnapshot: needleSizeSnapshot,
            needleLengthSnapshot: needleLengthSnapshot,
            workspaceDisplayMode: workspaceDisplayMode,
            workspaceSheetPosition: workspaceSheetPosition,
            rowCounter: rowCounter,
            workSessions: workSessions,
            relatedSkillIds: relatedSkillIds,
            createdAt: createdAt,
            updatedAt: date,
            deletedAt: deletedAt,
            syncStatus: syncStatus
        )
    }

    func replacingNeedle(
        with needle: Needle?,
        at date: Date = Date()
    ) -> KnittingProject {
        KnittingProject(
            id: id,
            ownerId: ownerId,
            name: name,
            status: status,
            isFavorite: isFavorite,
            memo: memo,
            startDate: startDate,
            targetDate: targetDate,
            finishedAt: finishedAt,
            lastWorkedAt: lastWorkedAt,
            patternCopy: patternCopy,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            yarnBrandSnapshot: yarnBrandSnapshot,
            yarnColorwaySnapshot: yarnColorwaySnapshot,
            yarnWeightSnapshot: yarnWeightSnapshot,
            needleId: needle?.id,
            needleNameSnapshot: needle?.name,
            needleTypeSnapshot: needle?.needleType,
            needleSizeSnapshot: needle?.size,
            needleLengthSnapshot: needle?.length,
            workspaceDisplayMode: workspaceDisplayMode,
            workspaceSheetPosition: workspaceSheetPosition,
            rowCounter: rowCounter,
            workSessions: workSessions,
            relatedSkillIds: relatedSkillIds,
            createdAt: createdAt,
            updatedAt: date,
            deletedAt: deletedAt,
            syncStatus: syncStatus
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
        targetDate: Date? = nil,
        finishedAt: Date? = nil,
        lastWorkedAt: Date? = nil,
        patternCopy: ProjectPatternCopy? = nil,
        workspaceDisplayMode: ProjectWorkspaceDisplayMode? = nil,
        workspaceSheetPosition: ProjectWorkspaceSheetPosition? = nil,
        rowCounter: RowCounter? = nil,
        workSessions: [WorkSession]? = nil,
        relatedSkillIds: [UUID]? = nil,
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> KnittingProject {
        KnittingProject(
            id: id,
            ownerId: ownerId,
            name: name ?? self.name,
            status: status ?? self.status,
            isFavorite: isFavorite ?? self.isFavorite,
            memo: memo ?? self.memo,
            startDate: startDate ?? self.startDate,
            targetDate: targetDate ?? self.targetDate,
            finishedAt: finishedAt ?? self.finishedAt,
            lastWorkedAt: lastWorkedAt ?? self.lastWorkedAt,
            patternCopy: patternCopy ?? self.patternCopy,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            yarnBrandSnapshot: yarnBrandSnapshot,
            yarnColorwaySnapshot: yarnColorwaySnapshot,
            yarnWeightSnapshot: yarnWeightSnapshot,
            needleId: needleId,
            needleNameSnapshot: needleNameSnapshot,
            needleTypeSnapshot: needleTypeSnapshot,
            needleSizeSnapshot: needleSizeSnapshot,
            needleLengthSnapshot: needleLengthSnapshot,
            workspaceDisplayMode: workspaceDisplayMode ?? self.workspaceDisplayMode,
            workspaceSheetPosition: workspaceSheetPosition ?? self.workspaceSheetPosition,
            rowCounter: rowCounter ?? self.rowCounter,
            workSessions: workSessions ?? self.workSessions,
            relatedSkillIds: relatedSkillIds ?? self.relatedSkillIds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
