//
//  GaugeRecord.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

enum GaugeMeasurementStage: String, CaseIterable, Codable, Identifiable, Hashable {
    case beforeWash
    case afterWash

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .beforeWash:
            "세탁 전"
        case .afterWash:
            "세탁 후"
        }
    }
}

struct GaugeRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID?
    let projectNameSnapshot: String?
    let patternNameSnapshot: String?
    let measurementStage: GaugeMeasurementStage
    let sampleWidthCm: Double
    let sampleHeightCm: Double
    let stitchCount: Double
    let rowCount: Double
    let targetWidthCm: Double
    let targetHeightCm: Double
    let stitchesPer10Cm: Double
    let rowsPer10Cm: Double
    let targetStitches: Int
    let targetRows: Int
    let needle: String
    let memo: String
    let measuredAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID? = nil,
        projectNameSnapshot: String? = nil,
        patternNameSnapshot: String? = nil,
        measurementStage: GaugeMeasurementStage,
        sampleWidthCm: Double,
        sampleHeightCm: Double,
        stitchCount: Double,
        rowCount: Double,
        targetWidthCm: Double,
        targetHeightCm: Double,
        stitchesPer10Cm: Double,
        rowsPer10Cm: Double,
        targetStitches: Int,
        targetRows: Int,
        needle: String,
        memo: String,
        measuredAt: Date,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.projectNameSnapshot = projectNameSnapshot
        self.patternNameSnapshot = patternNameSnapshot
        self.measurementStage = measurementStage
        self.sampleWidthCm = sampleWidthCm
        self.sampleHeightCm = sampleHeightCm
        self.stitchCount = stitchCount
        self.rowCount = rowCount
        self.targetWidthCm = targetWidthCm
        self.targetHeightCm = targetHeightCm
        self.stitchesPer10Cm = stitchesPer10Cm
        self.rowsPer10Cm = rowsPer10Cm
        self.targetStitches = targetStitches
        self.targetRows = targetRows
        self.needle = needle
        self.memo = memo
        self.measuredAt = measuredAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        ownerId: String? = nil,
        syncStatus: SyncStatus? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) -> GaugeRecord {
        GaugeRecord(
            id: id,
            ownerId: ownerId ?? self.ownerId,
            projectId: projectId,
            projectNameSnapshot: projectNameSnapshot,
            patternNameSnapshot: patternNameSnapshot,
            measurementStage: measurementStage,
            sampleWidthCm: sampleWidthCm,
            sampleHeightCm: sampleHeightCm,
            stitchCount: stitchCount,
            rowCount: rowCount,
            targetWidthCm: targetWidthCm,
            targetHeightCm: targetHeightCm,
            stitchesPer10Cm: stitchesPer10Cm,
            rowsPer10Cm: rowsPer10Cm,
            targetStitches: targetStitches,
            targetRows: targetRows,
            needle: needle,
            memo: memo,
            measuredAt: measuredAt,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            deletedAt: deletedAt ?? self.deletedAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }

    func linking(to project: KnittingProject, at date: Date = Date()) -> GaugeRecord {
        GaugeRecord(
            id: id,
            ownerId: ownerId ?? project.ownerId,
            projectId: project.id,
            projectNameSnapshot: project.name,
            patternNameSnapshot: patternNameSnapshot ?? project.patternCopy?.titleSnapshot,
            measurementStage: measurementStage,
            sampleWidthCm: sampleWidthCm,
            sampleHeightCm: sampleHeightCm,
            stitchCount: stitchCount,
            rowCount: rowCount,
            targetWidthCm: targetWidthCm,
            targetHeightCm: targetHeightCm,
            stitchesPer10Cm: stitchesPer10Cm,
            rowsPer10Cm: rowsPer10Cm,
            targetStitches: targetStitches,
            targetRows: targetRows,
            needle: needle,
            memo: memo,
            measuredAt: measuredAt,
            createdAt: createdAt,
            updatedAt: date,
            deletedAt: deletedAt,
            syncStatus: mutationSyncStatus
        )
    }

    func unlinkingFromProject(at date: Date = Date()) -> GaugeRecord {
        GaugeRecord(
            id: id,
            ownerId: ownerId,
            projectId: nil,
            projectNameSnapshot: nil,
            patternNameSnapshot: patternNameSnapshot,
            measurementStage: measurementStage,
            sampleWidthCm: sampleWidthCm,
            sampleHeightCm: sampleHeightCm,
            stitchCount: stitchCount,
            rowCount: rowCount,
            targetWidthCm: targetWidthCm,
            targetHeightCm: targetHeightCm,
            stitchesPer10Cm: stitchesPer10Cm,
            rowsPer10Cm: rowsPer10Cm,
            targetStitches: targetStitches,
            targetRows: targetRows,
            needle: needle,
            memo: memo,
            measuredAt: measuredAt,
            createdAt: createdAt,
            updatedAt: date,
            deletedAt: deletedAt,
            syncStatus: mutationSyncStatus
        )
    }

    private var mutationSyncStatus: SyncStatus {
        syncStatus == .synced ? .pendingUpload : syncStatus
    }
}

struct GaugeWashComparison: Hashable {
    let before: GaugeRecord
    let after: GaugeRecord

    var stitchDeltaPer10Cm: Double {
        after.stitchesPer10Cm - before.stitchesPer10Cm
    }

    var rowDeltaPer10Cm: Double {
        after.rowsPer10Cm - before.rowsPer10Cm
    }
}
