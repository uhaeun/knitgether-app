//
//  ProjectFormData.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct ProjectFormData {
    var name: String
    var status: ProjectStatus
    var startDate: Date
    var hasTargetDate: Bool
    var targetDate: Date
    var hasFinishedAt: Bool
    var finishedAt: Date
    var memo: String
    var isFavorite: Bool
    var patternName: String
    var patternDocumentId: UUID?
    var patternDesignerSnapshot: String
    var patternFileNameSnapshot: String
    var patternPageCountSnapshot: Int?
    var yarnId: UUID?
    var yarnNameSnapshot: String
    var yarnBrandSnapshot: String
    var yarnColorwaySnapshot: String
    var yarnWeightSnapshot: String
    var needleId: UUID?
    var needleNameSnapshot: String
    var needleTypeSnapshot: String
    var needleSizeSnapshot: String
    var needleLengthSnapshot: String

    init(
        name: String = "",
        status: ProjectStatus = .planned,
        startDate: Date = Date(),
        hasTargetDate: Bool = false,
        targetDate: Date = Date(),
        hasFinishedAt: Bool = false,
        finishedAt: Date = Date(),
        memo: String = "",
        isFavorite: Bool = false,
        patternName: String = "",
        patternDocumentId: UUID? = nil,
        patternDesignerSnapshot: String = "",
        patternFileNameSnapshot: String = "",
        patternPageCountSnapshot: Int? = nil,
        yarnId: UUID? = nil,
        yarnNameSnapshot: String = "",
        yarnBrandSnapshot: String = "",
        yarnColorwaySnapshot: String = "",
        yarnWeightSnapshot: String = "",
        needleId: UUID? = nil,
        needleNameSnapshot: String = "",
        needleTypeSnapshot: String = "",
        needleSizeSnapshot: String = "",
        needleLengthSnapshot: String = ""
    ) {
        self.name = name
        self.status = status
        self.startDate = startDate
        self.hasTargetDate = hasTargetDate
        self.targetDate = targetDate
        self.hasFinishedAt = hasFinishedAt
        self.finishedAt = finishedAt
        self.memo = memo
        self.isFavorite = isFavorite
        self.patternName = patternName
        self.patternDocumentId = patternDocumentId
        self.patternDesignerSnapshot = patternDesignerSnapshot
        self.patternFileNameSnapshot = patternFileNameSnapshot
        self.patternPageCountSnapshot = patternPageCountSnapshot
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
    }

    init(project: KnittingProject) {
        name = project.name
        status = project.status
        startDate = project.startDate
        hasTargetDate = project.targetDate != nil
        targetDate = project.targetDate ?? Date()
        hasFinishedAt = project.finishedAt != nil
        finishedAt = project.finishedAt ?? Date()
        memo = project.memo
        isFavorite = project.isFavorite
        patternName = project.patternCopy?.titleSnapshot ?? ""
        patternDocumentId = project.patternCopy?.sourcePatternDocumentId
        patternDesignerSnapshot = project.patternCopy?.designerSnapshot ?? ""
        patternFileNameSnapshot = project.patternCopy?.fileNameSnapshot ?? ""
        patternPageCountSnapshot = project.patternCopy?.pageCountSnapshot
        yarnId = project.yarnId
        yarnNameSnapshot = project.yarnNameSnapshot ?? ""
        yarnBrandSnapshot = project.yarnBrandSnapshot ?? ""
        yarnColorwaySnapshot = project.yarnColorwaySnapshot ?? ""
        yarnWeightSnapshot = project.yarnWeightSnapshot ?? ""
        needleId = project.needleId
        needleNameSnapshot = project.needleNameSnapshot ?? ""
        needleTypeSnapshot = project.needleTypeSnapshot ?? ""
        needleSizeSnapshot = project.needleSizeSnapshot ?? ""
        needleLengthSnapshot = project.needleLengthSnapshot ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMemo: String {
        memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedPatternName: String {
        patternName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedPatternDesignerSnapshot: String? {
        nullableTrimmed(patternDesignerSnapshot)
    }

    var trimmedPatternFileNameSnapshot: String? {
        nullableTrimmed(patternFileNameSnapshot)
    }

    var trimmedYarnNameSnapshot: String? {
        nullableTrimmed(yarnNameSnapshot)
    }

    var trimmedYarnBrandSnapshot: String? {
        nullableTrimmed(yarnBrandSnapshot)
    }

    var trimmedYarnColorwaySnapshot: String? {
        nullableTrimmed(yarnColorwaySnapshot)
    }

    var trimmedYarnWeightSnapshot: String? {
        nullableTrimmed(yarnWeightSnapshot)
    }

    var trimmedNeedleNameSnapshot: String? {
        nullableTrimmed(needleNameSnapshot)
    }

    var trimmedNeedleTypeSnapshot: String? {
        nullableTrimmed(needleTypeSnapshot)
    }

    var trimmedNeedleSizeSnapshot: String? {
        nullableTrimmed(needleSizeSnapshot)
    }

    var trimmedNeedleLengthSnapshot: String? {
        nullableTrimmed(needleLengthSnapshot)
    }

    var yarnSummaryText: String? {
        [
            trimmedYarnNameSnapshot,
            trimmedYarnBrandSnapshot,
            trimmedYarnColorwaySnapshot,
            trimmedYarnWeightSnapshot
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
        .nilIfEmpty
    }

    var needleSummaryText: String? {
        [
            trimmedNeedleNameSnapshot,
            trimmedNeedleTypeSnapshot,
            trimmedNeedleSizeSnapshot,
            trimmedNeedleLengthSnapshot
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
        .nilIfEmpty
    }

    var patternSummaryText: String? {
        [
            patternDocumentId == nil ? nil : "도안 창고",
            trimmedPatternDesignerSnapshot,
            trimmedPatternFileNameSnapshot
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
        .nilIfEmpty
    }

    var effectiveTargetDate: Date? {
        hasTargetDate ? targetDate : nil
    }

    var effectiveFinishedAt: Date? {
        hasFinishedAt ? finishedAt : nil
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }

    mutating func selectYarn(_ yarn: Yarn?) {
        yarnId = yarn?.id
        yarnNameSnapshot = yarn?.name ?? ""
        yarnBrandSnapshot = yarn?.brand ?? ""
        yarnColorwaySnapshot = yarn?.colorway ?? ""
        yarnWeightSnapshot = yarn?.weight ?? ""
    }

    mutating func selectNeedle(_ needle: Needle?) {
        needleId = needle?.id
        needleNameSnapshot = needle?.name ?? ""
        needleTypeSnapshot = needle?.needleType ?? ""
        needleSizeSnapshot = needle?.size ?? ""
        needleLengthSnapshot = needle?.length ?? ""
    }

    mutating func selectPattern(_ pattern: PatternDocument?) {
        patternDocumentId = pattern?.id
        patternName = pattern?.title ?? ""
        patternDesignerSnapshot = pattern?.designer ?? ""
        patternFileNameSnapshot = pattern?.fileName ?? ""
        patternPageCountSnapshot = pattern?.pageCount
    }

    mutating func setManualPatternName(_ name: String) {
        patternDocumentId = nil
        patternName = name
        patternDesignerSnapshot = ""
        patternFileNameSnapshot = ""
        patternPageCountSnapshot = nil
    }

    private func nullableTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
