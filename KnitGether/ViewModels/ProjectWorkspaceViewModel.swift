//
//  ProjectWorkspaceViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import CoreGraphics
import Foundation
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

enum PatternInteractionMode: String, CaseIterable, Identifiable {
    case viewer = "뷰어 모드"
    case drawing = "그리기 모드"

    var id: String {
        rawValue
    }
}

struct ResolvedSkillTag: Identifiable, Hashable {
    let displayTag: String
    let skill: Skill?

    var id: String {
        displayTag
    }

    var isRegistered: Bool {
        skill != nil
    }

    var level: String {
        skill?.userLevel ?? "미등록"
    }

    var detailText: String {
        guard let skill else {
            return "미등록 스킬"
        }

        return "\(skill.name), \(level)"
    }
}

struct PatternRowInstructionSuggestion: Identifiable, Hashable {
    let rowNumber: Int
    let instructionText: String
    let skillTags: [String]

    var id: String {
        "\(rowNumber)-\(instructionText)-\(skillTags.joined(separator: ","))"
    }

    var skillTagsText: String {
        skillTags.joined(separator: ",")
    }
}

@MainActor
final class ProjectWorkspaceViewModel: ObservableObject {
    @Published private(set) var project: KnittingProject
    @Published private(set) var displayMode: ProjectWorkspaceDisplayMode
    @Published private(set) var sheetPosition: ProjectWorkspaceSheetPosition
    @Published var interactionMode: PatternInteractionMode = .viewer
    @Published var memoText: String
    @Published private(set) var currentRow: Int
    @Published private(set) var currentSessionElapsed: TimeInterval = 0
    @Published private(set) var relatedSkills: [Skill] = []
    @Published private(set) var patternRowInstructionSuggestions: [PatternRowInstructionSuggestion] = []
    @Published private(set) var availablePatterns: [PatternDocument] = []
    @Published private(set) var attachedYarn: Yarn?
    @Published private(set) var attachedNeedle: Needle?
    @Published private(set) var availableNeedles: [Needle] = []
    @Published private(set) var availableTools: [ToolItem] = []
    @Published private(set) var linkedTools: [ToolItem] = []
    @Published private(set) var yarnUsages: [ProjectYarnUsage] = []
    @Published private(set) var gaugeRecords: [GaugeRecord] = []
    @Published private(set) var progressPhotos: [ProjectProgressPhoto] = []
    @Published private(set) var attachedPatternFileURL: URL?
    @Published var drawingData: Data?
    @Published private(set) var isTrackingTime = false
    @Published private(set) var isRetryingSync = false
    @Published private(set) var errorMessage: String?

    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository
    private let libraryRepository: any LibraryRepository
    private let gaugeRecordRepository: (any GaugeRecordRepository)?
    private let progressPhotoRepository: (any ProjectProgressPhotoRepository)?
    private var sessionStartedAt: Date?
    private let minimumWorkSessionDuration: TimeInterval = 10
    private var isDeleted = false

    init(
        project: KnittingProject,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        skillRepository: any SkillRepository,
        libraryRepository: any LibraryRepository,
        gaugeRecordRepository: (any GaugeRecordRepository)? = nil,
        progressPhotoRepository: (any ProjectProgressPhotoRepository)? = nil
    ) {
        self.project = project
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.skillRepository = skillRepository
        self.libraryRepository = libraryRepository
        self.gaugeRecordRepository = gaugeRecordRepository
        self.progressPhotoRepository = progressPhotoRepository
        displayMode = project.workspaceDisplayMode ?? .patternAndCounter
        sheetPosition = Self.resolvedSheetPosition(for: project)
        memoText = project.memo
        currentRow = project.rowCounter.currentRow
        attachedPatternFileURL = project.patternCopy.flatMap { patternRepository.fileURL(for: $0) }
    }

    var hasUnsavedMemoChanges: Bool {
        memoText != project.memo
    }

    var rowCounter: RowCounter {
        project.rowCounter
    }

    var currentInstruction: RowInstruction? {
        rowCounter.rowInstructions.first { $0.rowNumber == currentRow }
    }

    var currentResolvedSkillTags: [ResolvedSkillTag] {
        guard let currentInstruction else {
            return []
        }

        return resolvedSkillTags(for: currentInstruction)
    }

    var currentLearningSkillTags: [ResolvedSkillTag] {
        currentResolvedSkillTags.filter { tag in
            let level = SkillLevelFormatter.normalizedLevel(tag.level)
            return tag.isRegistered && (level == "몰라요" || level == "헷갈려요")
        }
    }

    var rowGuideProgress: Double? {
        guard let targetRow = rowCounter.targetRow, targetRow > 0 else {
            return nil
        }

        return min(max(Double(currentRow) / Double(targetRow), 0), 1)
    }

    var yarnUsageTotal: Int {
        yarnUsages.reduce(0) { total, usage in
            total + usage.quantityUsed
        }
    }

    var workSessionsByMostRecent: [WorkSession] {
        project.workSessions.sorted { first, second in
            if first.startedAt == second.startedAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.startedAt > second.startedAt
        }
    }

    var workSessionStatistics: WorkSessionStatistics {
        WorkSessionStatistics(sessions: project.workSessions)
    }

    var linkedGaugeRecords: [GaugeRecord] {
        gaugeRecords
            .filter { $0.projectId == project.id }
            .sorted { first, second in
                if first.measuredAt == second.measuredAt {
                    return first.id.uuidString < second.id.uuidString
                }
                return first.measuredAt > second.measuredAt
            }
    }

    var availableGaugeRecordsForLinking: [GaugeRecord] {
        gaugeRecords
            .filter { $0.projectId == nil }
            .sorted { first, second in
                if first.measuredAt == second.measuredAt {
                    return first.id.uuidString < second.id.uuidString
                }
                return first.measuredAt > second.measuredAt
            }
    }

    var linkedGaugeWashComparison: GaugeWashComparison? {
        guard
            let before = linkedGaugeRecords
                .filter({ $0.measurementStage == .beforeWash })
                .max(by: { $0.measuredAt < $1.measuredAt }),
            let after = linkedGaugeRecords
                .filter({ $0.measurementStage == .afterWash })
                .max(by: { $0.measuredAt < $1.measuredAt })
        else {
            return nil
        }

        return GaugeWashComparison(before: before, after: after)
    }

    var availableToolsForLinking: [ToolItem] {
        let linkedToolIds = Set(linkedTools.map(\.id))
        return availableTools.filter { !linkedToolIds.contains($0.id) }
    }

    var yarnUsageSummaryText: String {
        guard project.yarnId != nil else {
            return "연결된 실 없음"
        }

        let remainingText = attachedYarn.map { "남은 수량 \($0.quantity)개" } ?? "남은 수량 확인 전"

        if yarnUsageTotal == 0 {
            return "\(remainingText) · 사용 기록 없음"
        }

        return "\(remainingText) · 누적 사용 \(yarnUsageTotal)개"
    }

    func loadRelatedSkills() async {
        do {
            let skills = try await skillRepository.fetchSkills()
            let sourceText = await relatedSkillSourceText()
            let patternSourceText = await patternSkillSuggestionSourceText()
            let explicitSkillIds = Set(project.relatedSkillIds)

            relatedSkills = skills.filter { skill in
                explicitSkillIds.contains(skill.id)
                    || Self.containsAbbreviation(skill.abbreviation, in: sourceText)
            }
            patternRowInstructionSuggestions = Self.patternRowInstructionSuggestions(
                from: patternSourceText,
                skills: relatedSkills,
                existingRowNumbers: Set(rowCounter.rowInstructions.map(\.rowNumber)),
                fallbackStartRow: max(currentRow, 1)
            )
            errorMessage = nil
        } catch {
            errorMessage = "관련 스킬을 불러오지 못했어요."
        }
    }

    func loadAvailablePatterns() async {
        do {
            availablePatterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안 창고를 불러오지 못했어요."
        }
    }

    func loadYarnUsage() async {
        guard let yarnId = project.yarnId else {
            attachedYarn = nil
            yarnUsages = []
            return
        }

        do {
            let yarns = try await libraryRepository.fetchYarns()
            let usages = try await libraryRepository.fetchYarnUsages(forProjectId: project.id)

            attachedYarn = yarns.first { $0.id == yarnId }
            yarnUsages = usages
            errorMessage = nil
        } catch {
            errorMessage = "실 사용 기록을 불러오지 못했어요."
        }
    }

    func loadGaugeRecords() async {
        guard let gaugeRecordRepository else {
            gaugeRecords = []
            return
        }

        do {
            gaugeRecords = try await gaugeRecordRepository.fetchGaugeRecords()
                .sorted { $0.measuredAt > $1.measuredAt }
            errorMessage = nil
        } catch {
            errorMessage = "게이지 기록을 불러오지 못했어요."
        }
    }

    @discardableResult
    func linkGaugeRecord(_ record: GaugeRecord) async -> Bool {
        guard let gaugeRecordRepository else {
            errorMessage = "게이지 기록 저장소가 연결되지 않았어요."
            return false
        }

        do {
            let savedRecord = try await gaugeRecordRepository.saveGaugeRecord(record.linking(to: project))
            upsertGaugeRecord(savedRecord)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "게이지 기록을 연결하지 못했어요."
            return false
        }
    }

    @discardableResult
    func unlinkGaugeRecord(_ record: GaugeRecord) async -> Bool {
        guard let gaugeRecordRepository else {
            errorMessage = "게이지 기록 저장소가 연결되지 않았어요."
            return false
        }

        do {
            let savedRecord = try await gaugeRecordRepository.saveGaugeRecord(record.unlinkingFromProject())
            upsertGaugeRecord(savedRecord)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "게이지 기록 연결을 해제하지 못했어요."
            return false
        }
    }

    @discardableResult
    func deleteGaugeRecord(_ record: GaugeRecord) async -> Bool {
        guard let gaugeRecordRepository else {
            errorMessage = "게이지 기록 저장소가 연결되지 않았어요."
            return false
        }

        do {
            try await gaugeRecordRepository.deleteGaugeRecord(id: record.id)
            gaugeRecords.removeAll { $0.id == record.id }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "게이지 기록을 삭제하지 못했어요."
            return false
        }
    }

    @discardableResult
    func recordYarnUsage(quantityUsed: Int, memo: String) async -> Bool {
        guard quantityUsed > 0 else {
            errorMessage = "사용 수량은 1개 이상이어야 해요."
            return false
        }
        guard let yarnId = project.yarnId else {
            errorMessage = "프로젝트에 실을 먼저 연결해 주세요."
            return false
        }

        let now = Date()
        let usage = ProjectYarnUsage(
            ownerId: project.ownerId,
            projectId: project.id,
            projectNameSnapshot: project.name,
            yarnId: yarnId,
            yarnNameSnapshot: project.yarnNameSnapshot ?? attachedYarn?.name ?? "연결된 실",
            quantityUsed: quantityUsed,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )

        do {
            _ = try await libraryRepository.recordYarnUsage(usage)
            await loadYarnUsage()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "실 사용량을 저장하지 못했어요."
            return false
        }
    }

    @discardableResult
    func updateYarnUsage(
        _ usage: ProjectYarnUsage,
        quantityUsed: Int,
        memo: String
    ) async -> Bool {
        guard quantityUsed > 0 else {
            errorMessage = "사용 수량은 1개 이상이어야 해요."
            return false
        }

        let updatedUsage = ProjectYarnUsage(
            id: usage.id,
            ownerId: usage.ownerId,
            projectId: usage.projectId,
            projectNameSnapshot: usage.projectNameSnapshot ?? project.name,
            yarnId: usage.yarnId,
            yarnNameSnapshot: usage.yarnNameSnapshot,
            quantityUsed: quantityUsed,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            usedAt: usage.usedAt,
            createdAt: usage.createdAt,
            updatedAt: Date(),
            deletedAt: usage.deletedAt,
            syncStatus: usage.syncStatus
        )

        do {
            _ = try await libraryRepository.updateYarnUsage(updatedUsage)
            await loadYarnUsage()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "실 사용량을 수정하지 못했어요."
            return false
        }
    }

    @discardableResult
    func deleteYarnUsage(_ usage: ProjectYarnUsage) async -> Bool {
        do {
            try await libraryRepository.deleteYarnUsage(usage)
            await loadYarnUsage()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "실 사용량을 삭제하지 못했어요."
            return false
        }
    }

    func loadNeedles() async {
        do {
            availableNeedles = try await libraryRepository.fetchNeedles()
            refreshAttachedNeedle()
            errorMessage = nil
        } catch {
            errorMessage = "바늘 창고를 불러오지 못했어요."
        }
    }

    func loadTools() async {
        do {
            availableTools = try await libraryRepository.fetchTools()
            linkedTools = try await libraryRepository.fetchTools(forProjectId: project.id)
            errorMessage = nil
        } catch {
            errorMessage = "도구 창고를 불러오지 못했어요."
        }
    }

    @discardableResult
    func linkTool(_ tool: ToolItem) async -> Bool {
        do {
            let linkedTool = try await libraryRepository.linkTool(tool, toProjectId: project.id)
            upsertLinkedTool(linkedTool)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도구를 프로젝트에 연결하지 못했어요."
            return false
        }
    }

    @discardableResult
    func unlinkTool(_ tool: ToolItem) async -> Bool {
        do {
            try await libraryRepository.unlinkTool(tool, fromProjectId: project.id)
            linkedTools.removeAll { $0.id == tool.id }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도구 연결을 해제하지 못했어요."
            return false
        }
    }

    func loadProgressPhotos() async {
        guard let progressPhotoRepository else {
            progressPhotos = []
            return
        }

        do {
            progressPhotos = try await progressPhotoRepository.fetchProgressPhotos(projectId: project.id)
            errorMessage = nil
        } catch {
            errorMessage = "진행 사진을 불러오지 못했어요."
        }
    }

    @discardableResult
    func addProgressPhoto(
        imageData: Data,
        fileName: String,
        contentType: String,
        caption: String,
        takenAt: Date
    ) async -> Bool {
        guard let progressPhotoRepository else {
            errorMessage = "진행 사진 저장소가 연결되지 않았어요."
            return false
        }

        do {
            let photo = try await progressPhotoRepository.createProgressPhoto(
                projectId: project.id,
                imageData: imageData,
                fileName: fileName,
                contentType: contentType,
                caption: caption,
                takenAt: takenAt
            )
            upsertProgressPhoto(photo)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "진행 사진을 저장하지 못했어요."
            return false
        }
    }

    @discardableResult
    func updateProgressPhoto(
        _ photo: ProjectProgressPhoto,
        caption: String,
        takenAt: Date
    ) async -> Bool {
        guard let progressPhotoRepository else {
            errorMessage = "진행 사진 저장소가 연결되지 않았어요."
            return false
        }

        do {
            let updatedPhoto = try await progressPhotoRepository.updateProgressPhoto(
                photo,
                caption: caption,
                takenAt: takenAt
            )
            upsertProgressPhoto(updatedPhoto)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "진행 사진을 수정하지 못했어요."
            return false
        }
    }

    @discardableResult
    func deleteProgressPhoto(_ photo: ProjectProgressPhoto) async -> Bool {
        guard let progressPhotoRepository else {
            errorMessage = "진행 사진 저장소가 연결되지 않았어요."
            return false
        }

        do {
            try await progressPhotoRepository.deleteProgressPhoto(photo)
            progressPhotos.removeAll { $0.id == photo.id }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "진행 사진을 삭제하지 못했어요."
            return false
        }
    }

    func progressPhotoFileURL(for photo: ProjectProgressPhoto) -> URL? {
        progressPhotoRepository?.fileURL(for: photo)
    }

    @discardableResult
    func attachNeedle(_ needle: Needle) async -> Bool {
        let updatedProject = project.replacingNeedle(with: needle)
        let didSave = await persist(updatedProject, errorMessage: "바늘을 연결하지 못했어요.")

        if didSave {
            attachedNeedle = needle
        }

        return didSave
    }

    @discardableResult
    func unlinkNeedle() async -> Bool {
        let updatedProject = project.replacingNeedle(with: nil)
        let didUnlink = await persist(updatedProject, errorMessage: "바늘 연결을 해제하지 못했어요.")

        if didUnlink {
            attachedNeedle = nil
        }

        return didUnlink
    }

    func loadDrawingData() async {
        guard let patternCopy = project.patternCopy else {
            drawingData = nil
            return
        }

        do {
            drawingData = try await patternRepository.drawingData(for: patternCopy)
            errorMessage = nil
        } catch {
            errorMessage = "그리기 데이터를 불러오지 못했어요."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        defer {
            isRetryingSync = false
        }

        do {
            guard let refreshedProject = try await projectRepository.fetchProject(id: project.id) else {
                errorMessage = "프로젝트를 찾지 못했어요."
                return
            }

            project = refreshedProject
            displayMode = refreshedProject.workspaceDisplayMode ?? displayMode
            sheetPosition = Self.resolvedSheetPosition(for: refreshedProject)
            memoText = refreshedProject.memo
            currentRow = refreshedProject.rowCounter.currentRow
            refreshAttachedPatternFileURL()
            errorMessage = nil

            await loadRelatedSkills()
            await loadDrawingData()
            await loadYarnUsage()
        } catch {
            errorMessage = "프로젝트 저장 상태를 다시 확인하지 못했어요."
        }
    }

    func startWorkSession() {
        guard sessionStartedAt == nil, !isDeleted else {
            return
        }

        sessionStartedAt = Date()
        currentSessionElapsed = 0
        isTrackingTime = true
    }

    func refreshCurrentSessionElapsed() {
        guard let sessionStartedAt else {
            return
        }

        currentSessionElapsed = Date().timeIntervalSince(sessionStartedAt)
    }

    func finishWorkSession() async {
        guard let sessionStartedAt, !isDeleted else {
            return
        }

        let endedAt = Date()
        currentSessionElapsed = endedAt.timeIntervalSince(sessionStartedAt)
        self.sessionStartedAt = nil
        isTrackingTime = false

        guard currentSessionElapsed >= minimumWorkSessionDuration else {
            currentSessionElapsed = 0
            return
        }

        let updatedProject = project.recordingWorkSession(
            startedAt: sessionStartedAt,
            endedAt: endedAt
        )

        guard let session = updatedProject.workSessions.last else {
            return
        }

        do {
            let savedSession = try await projectRepository.saveWorkSession(session, forProjectId: project.id)
            applyProjectState(
                project.copy(
                    lastWorkedAt: endedAt,
                    workSessions: project.workSessions + [savedSession],
                    updatedAt: endedAt
                )
            )
            errorMessage = nil
        } catch {
            errorMessage = "작업 시간을 저장하지 못했어요."
        }
    }

    @discardableResult
    func updateWorkSessionMemo(sessionID: UUID, memo: String) async -> Bool {
        guard project.workSessions.contains(where: { $0.id == sessionID }) else {
            errorMessage = "작업 세션을 찾지 못했어요."
            return false
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMemo = trimmedMemo.isEmpty ? nil : trimmedMemo
        let now = Date()
        guard let updatedSession = project.workSessions.first(where: { $0.id == sessionID })?.updatingMemo(normalizedMemo, at: now) else {
            errorMessage = "작업 세션을 찾지 못했어요."
            return false
        }

        let didSave: Bool
        do {
            let savedSession = try await projectRepository.saveWorkSession(updatedSession, forProjectId: project.id)
            let updatedSessions = project.workSessions.map { session in
                session.id == sessionID ? savedSession : session
            }
            applyProjectState(
                project.copy(
                    workSessions: updatedSessions,
                    updatedAt: savedSession.updatedAt
                )
            )
            errorMessage = nil
            didSave = true
        } catch {
            errorMessage = "작업 세션 메모를 저장하지 못했어요."
            didSave = false
        }

        if didSave {
            await loadRelatedSkills()
        }

        return didSave
    }

    @discardableResult
    func deleteWorkSession(sessionID: UUID) async -> Bool {
        guard project.workSessions.contains(where: { $0.id == sessionID }) else {
            errorMessage = "작업 세션을 찾지 못했어요."
            return false
        }

        let didDelete: Bool
        do {
            try await projectRepository.deleteWorkSession(id: sessionID, forProjectId: project.id)
            applyProjectState(
                project.copy(
                    workSessions: project.workSessions.filter { $0.id != sessionID }
                )
            )
            errorMessage = nil
            didDelete = true
        } catch {
            errorMessage = "작업 세션을 삭제하지 못했어요."
            didDelete = false
        }

        if didDelete {
            await loadRelatedSkills()
        }

        return didDelete
    }

    func decrementRow() async {
        await updateRow(to: max(0, currentRow - 1))
    }

    func incrementRow() async {
        await updateRow(to: currentRow + 1)
    }

    func updateCurrentRow(_ row: Int) async {
        await updateRow(to: max(0, row))
    }

    func resetCurrentRow() async {
        await updateRow(to: 0)
    }

    func completeProject() async {
        guard project.status != .fo else {
            return
        }

        let updatedProject = project.copy(
            status: .fo,
            finishedAt: project.finishedAt ?? Date()
        )
        await persist(updatedProject, errorMessage: "프로젝트를 완료로 변경하지 못했어요.")
    }

    func updateDisplayMode(_ mode: ProjectWorkspaceDisplayMode) async {
        guard mode != displayMode else {
            return
        }

        displayMode = mode
        let updatedProject = project.copy(workspaceDisplayMode: mode)
        await persist(updatedProject, errorMessage: "작업 화면 모드를 저장하지 못했어요.")
    }

    func updateCounterMode(_ mode: RowCounterMode) async {
        guard mode != rowCounter.mode else {
            return
        }

        let updatedCounter = makeRowCounter(mode: mode)
        await persistRowCounter(updatedCounter, errorMessage: "카운터 모드를 저장하지 못했어요.")
    }

    func updateTargetRow(_ targetRow: Int?) async {
        let normalizedTargetRow = targetRow.flatMap { $0 > 0 ? $0 : nil }
        let updatedCounter = makeRowCounter(targetRow: normalizedTargetRow)
        await persistRowCounter(updatedCounter, errorMessage: "총 단수를 저장하지 못했어요.")
    }

    func updateCounterSectionName(_ sectionName: String) async {
        let trimmedSectionName = sectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedCounter = makeRowCounter(sectionName: trimmedSectionName.isEmpty ? nil : trimmedSectionName)
        await persistRowCounter(updatedCounter, errorMessage: "섹션을 저장하지 못했어요.")
    }

    func updateCounterMemo(_ memo: String) async {
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedCounter = makeRowCounter(memo: trimmedMemo.isEmpty ? nil : trimmedMemo)
        await persistRowCounter(updatedCounter, errorMessage: "카운터 메모를 저장하지 못했어요.")
    }

    func updateSheetPosition(_ position: ProjectWorkspaceSheetPosition) async {
        guard position != sheetPosition else {
            return
        }

        sheetPosition = position
        let updatedProject = project.copy(workspaceSheetPosition: position)
        await persist(updatedProject, errorMessage: "작업 화면 위치를 저장하지 못했어요.")
    }

    func saveDrawingData(_ data: Data) async {
        guard let patternCopy = project.patternCopy else {
            errorMessage = "도안을 추가한 뒤 그리기를 사용할 수 있어요."
            return
        }

        do {
            let updatedPatternCopy = try await patternRepository.saveDrawingData(data, for: patternCopy)
            let updatedProject = project.copy(patternCopy: updatedPatternCopy)
            try await projectRepository.saveProject(updatedProject)
            let savedProject = await latestProjectState(afterSaving: updatedProject)
            applyProjectState(savedProject)
            drawingData = data
            errorMessage = nil
        } catch {
            errorMessage = "그리기를 저장하지 못했어요."
        }
    }

    func clearDrawingData() async {
        guard let patternCopy = project.patternCopy else {
            drawingData = nil
            return
        }

        do {
            let updatedPatternCopy = try await patternRepository.deleteDrawingData(for: patternCopy)
            let updatedProject = project.copy(patternCopy: updatedPatternCopy)
            try await projectRepository.saveProject(updatedProject)
            let savedProject = await latestProjectState(afterSaving: updatedProject)
            applyProjectState(savedProject)
            drawingData = nil
            errorMessage = nil
        } catch {
            errorMessage = "그리기를 삭제하지 못했어요."
        }
    }

    func saveMemo() async {
        let updatedProject = project.updatingMemo(to: memoText)
        await persist(updatedProject, errorMessage: "작업 메모를 저장하지 못했어요.")
        await loadRelatedSkills()
    }

    @discardableResult
    func attachNewPattern(fromFileAt fileURL: URL, storeInLibrary: Bool = false) async -> Bool {
        do {
            let patternCopy: ProjectPatternCopy
            if storeInLibrary {
                let pattern = try await patternRepository.createPattern(fromFileAt: fileURL)
                patternCopy = try await patternRepository.importPattern(pattern, forProjectId: project.id)
            } else {
                patternCopy = try await patternRepository.createProjectPatternCopy(
                    fromFileAt: fileURL,
                    forProjectId: project.id
                )
            }

            let updatedProject = project.copy(patternCopy: patternCopy)
            let didSave = await persist(updatedProject, errorMessage: "도안을 프로젝트에 추가하지 못했어요.")
            if didSave {
                drawingData = nil
                await loadRelatedSkills()
            }
            return didSave
        } catch {
            errorMessage = "도안을 프로젝트에 추가하지 못했어요."
            return false
        }
    }

    func attachPatternFromLibrary(_ pattern: PatternDocument) async {
        do {
            let patternCopy = try await patternRepository.importPattern(pattern, forProjectId: project.id)
            let updatedProject = project.copy(patternCopy: patternCopy)
            await persist(updatedProject, errorMessage: "도안을 Library에서 가져오지 못했어요.")
            drawingData = nil
            await loadRelatedSkills()
        } catch {
            errorMessage = "도안을 Library에서 가져오지 못했어요."
        }
    }

    @discardableResult
    func attachManualPattern(title: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "도안 이름을 입력해 주세요."
            return false
        }

        let now = Date()
        let patternCopy = ProjectPatternCopy(
            ownerId: project.ownerId,
            projectId: project.id,
            sourcePatternDocumentId: nil,
            titleSnapshot: trimmedTitle,
            designerSnapshot: nil,
            fileNameSnapshot: nil,
            localCopyPath: nil,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now
        )
        let updatedProject = project.copy(patternCopy: patternCopy)
        let didSave = await persist(updatedProject, errorMessage: "수동 도안을 연결하지 못했어요.")
        if didSave {
            drawingData = nil
            await loadRelatedSkills()
        }
        return didSave
    }

    func unlinkPattern() async {
        guard project.patternCopy != nil else {
            drawingData = nil
            attachedPatternFileURL = nil
            return
        }

        let updatedProject = project.replacingPatternCopy(with: nil)
        await persist(updatedProject, errorMessage: "도안 연결을 해제하지 못했어요.")

        if errorMessage == nil {
            drawingData = nil
            attachedPatternFileURL = nil
        }
    }

    func resolvedSkillTags(for instruction: RowInstruction) -> [ResolvedSkillTag] {
        skillTags(from: instruction.skillTags).map { tag in
            let matchedSkill = relatedSkills.first { skill in
                skill.abbreviation.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(tag) == .orderedSame
            }

            return ResolvedSkillTag(displayTag: tag, skill: matchedSkill)
        }
    }

    @discardableResult
    func addRowInstruction(rowNumber: Int, text: String, skillTags: String) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rowNumber > 0 else {
            errorMessage = "행 번호는 1 이상이어야 해요."
            return false
        }
        guard !trimmedText.isEmpty else {
            errorMessage = "행안내 내용을 입력해 주세요."
            return false
        }
        guard !rowCounter.rowInstructions.contains(where: { $0.rowNumber == rowNumber }) else {
            errorMessage = "이미 등록된 행 번호예요."
            return false
        }

        let now = Date()
        let instruction = RowInstruction(
            ownerId: project.ownerId,
            projectId: project.id,
            rowCounterId: rowCounter.id,
            rowNumber: rowNumber,
            instructionText: trimmedText,
            skillTags: normalizedSkillTags(skillTags),
            createdAt: now,
            updatedAt: now
        )
        return await saveRowInstructions(rowCounter.rowInstructions + [instruction])
    }

    @discardableResult
    func addRowInstruction(from suggestion: PatternRowInstructionSuggestion) async -> Bool {
        let didAdd = await addRowInstruction(
            rowNumber: suggestion.rowNumber,
            text: suggestion.instructionText,
            skillTags: suggestion.skillTagsText
        )

        if didAdd {
            patternRowInstructionSuggestions.removeAll { candidate in
                candidate.id == suggestion.id || candidate.rowNumber == suggestion.rowNumber
            }
        }

        return didAdd
    }

    @discardableResult
    func updateRowInstruction(
        _ instruction: RowInstruction,
        rowNumber: Int,
        text: String,
        skillTags: String
    ) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rowNumber > 0 else {
            errorMessage = "행 번호는 1 이상이어야 해요."
            return false
        }
        guard !trimmedText.isEmpty else {
            errorMessage = "행안내 내용을 입력해 주세요."
            return false
        }
        guard !rowCounter.rowInstructions.contains(where: { $0.id != instruction.id && $0.rowNumber == rowNumber }) else {
            errorMessage = "이미 등록된 행 번호예요."
            return false
        }

        let updatedInstruction = RowInstruction(
            id: instruction.id,
            ownerId: instruction.ownerId,
            projectId: instruction.projectId,
            rowCounterId: instruction.rowCounterId,
            rowNumber: rowNumber,
            instructionText: trimmedText,
            skillTags: normalizedSkillTags(skillTags),
            createdAt: instruction.createdAt,
            updatedAt: Date(),
            deletedAt: instruction.deletedAt,
            syncStatus: instruction.syncStatus
        )
        return await saveRowInstructions(
            rowCounter.rowInstructions.map { $0.id == instruction.id ? updatedInstruction : $0 }
        )
    }

    @discardableResult
    func deleteRowInstruction(_ instruction: RowInstruction) async -> Bool {
        await saveRowInstructions(rowCounter.rowInstructions.filter { $0.id != instruction.id })
    }

    @discardableResult
    func renumberRowInstructions() async -> Bool {
        let now = Date()
        let renumberedInstructions = rowCounter.rowInstructions
            .sorted { first, second in
                if first.rowNumber == second.rowNumber {
                    return first.instructionText.localizedStandardCompare(second.instructionText) == .orderedAscending
                }
                return first.rowNumber < second.rowNumber
            }
            .enumerated()
            .map { index, instruction in
                RowInstruction(
                    id: instruction.id,
                    ownerId: instruction.ownerId,
                    projectId: instruction.projectId,
                    rowCounterId: instruction.rowCounterId,
                    rowNumber: index + 1,
                    instructionText: instruction.instructionText,
                    skillTags: instruction.skillTags,
                    createdAt: instruction.createdAt,
                    updatedAt: now,
                    deletedAt: instruction.deletedAt,
                    syncStatus: instruction.syncStatus
                )
            }

        return await saveRowInstructions(renumberedInstructions)
    }

    @discardableResult
    func addBulkRowInstructions(startRowNumber: Int, lines: String) async -> Bool {
        guard startRowNumber > 0 else {
            errorMessage = "시작 행 번호는 1 이상이어야 해요."
            return false
        }

        let parsedLines = lines
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parsedLines.isEmpty else {
            errorMessage = "붙여넣을 행안내 내용을 입력해 주세요."
            return false
        }

        let existingRows = Set(rowCounter.rowInstructions.map(\.rowNumber))
        let plannedRows = parsedLines.indices.map { startRowNumber + $0 }
        guard plannedRows.allSatisfy({ !existingRows.contains($0) }) else {
            errorMessage = "이미 등록된 행 번호가 포함되어 있어요."
            return false
        }

        let now = Date()
        let newInstructions = parsedLines.enumerated().map { offset, text in
            RowInstruction(
                ownerId: project.ownerId,
                projectId: project.id,
                rowCounterId: rowCounter.id,
                rowNumber: startRowNumber + offset,
                instructionText: text,
                createdAt: now,
                updatedAt: now
            )
        }
        return await saveRowInstructions(rowCounter.rowInstructions + newInstructions)
    }

    @discardableResult
    func updateProject(with formData: ProjectFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            return false
        }

        let updatedProject = KnittingProject(
            id: project.id,
            ownerId: project.ownerId,
            name: formData.trimmedName,
            status: formData.status,
            isFavorite: formData.isFavorite,
            memo: formData.trimmedMemo,
            startDate: formData.startDate,
            targetDate: formData.effectiveTargetDate,
            finishedAt: formData.effectiveFinishedAt,
            lastWorkedAt: project.lastWorkedAt,
            patternCopy: project.patternCopy,
            yarnId: formData.yarnId,
            yarnNameSnapshot: formData.trimmedYarnNameSnapshot,
            yarnBrandSnapshot: formData.trimmedYarnBrandSnapshot,
            yarnColorwaySnapshot: formData.trimmedYarnColorwaySnapshot,
            yarnWeightSnapshot: formData.trimmedYarnWeightSnapshot,
            needleId: formData.needleId,
            needleNameSnapshot: formData.trimmedNeedleNameSnapshot,
            needleTypeSnapshot: formData.trimmedNeedleTypeSnapshot,
            needleSizeSnapshot: formData.trimmedNeedleSizeSnapshot,
            needleLengthSnapshot: formData.trimmedNeedleLengthSnapshot,
            workspaceDisplayMode: project.workspaceDisplayMode,
            workspaceSheetPosition: project.workspaceSheetPosition,
            rowCounter: project.rowCounter,
            workSessions: project.workSessions,
            relatedSkillIds: project.relatedSkillIds,
            createdAt: project.createdAt,
            updatedAt: Date(),
            deletedAt: project.deletedAt,
            syncStatus: project.syncStatus
        )

        do {
            try await projectRepository.saveProject(updatedProject)
            let savedProject = await latestProjectState(afterSaving: updatedProject)
            applyProjectState(savedProject)
            errorMessage = nil
            await loadRelatedSkills()
            return true
        } catch {
            errorMessage = "프로젝트를 수정하지 못했어요."
            return false
        }
    }

    func deleteProject() async -> Bool {
        do {
            try await projectRepository.deleteProject(id: project.id)
            isDeleted = true
            sessionStartedAt = nil
            isTrackingTime = false
            errorMessage = nil
            return true
        } catch {
            errorMessage = "프로젝트를 삭제하지 못했어요."
            return false
        }
    }

    private func updateRow(to row: Int) async {
        guard row != currentRow else {
            return
        }

        let updatedProject = project.updatingRow(to: row)
        await persistRowCounter(updatedProject.rowCounter, updatedProject: updatedProject, errorMessage: "단수를 저장하지 못했어요.")
    }

    @discardableResult
    private func persist(_ updatedProject: KnittingProject, errorMessage: String) async -> Bool {
        do {
            try await projectRepository.saveProject(updatedProject)
            let savedProject = await latestProjectState(afterSaving: updatedProject)
            applyProjectState(savedProject)
            self.errorMessage = nil
            return true
        } catch {
            self.errorMessage = errorMessage
            return false
        }
    }

    private func latestProjectState(afterSaving updatedProject: KnittingProject) async -> KnittingProject {
        (try? await projectRepository.fetchProject(id: updatedProject.id)) ?? updatedProject
    }

    @discardableResult
    private func persistRowCounter(
        _ updatedCounter: RowCounter,
        updatedProject: KnittingProject? = nil,
        errorMessage: String
    ) async -> Bool {
        let localProject = updatedProject ?? project.copy(rowCounter: updatedCounter)

        do {
            let savedCounter = try await projectRepository.saveRowCounter(updatedCounter, forProjectId: project.id)
            let mergedProject = localProject.copy(rowCounter: savedCounter, updatedAt: savedCounter.updatedAt)
            let savedProject = await latestProjectState(afterSaving: mergedProject)
            applyProjectState(savedProject)
            self.errorMessage = nil
            return true
        } catch {
            self.errorMessage = errorMessage
            return false
        }
    }

    private func applyProjectState(_ updatedProject: KnittingProject) {
        project = updatedProject
        displayMode = updatedProject.workspaceDisplayMode ?? displayMode
        sheetPosition = Self.resolvedSheetPosition(for: updatedProject)
        memoText = updatedProject.memo
        currentRow = updatedProject.rowCounter.currentRow
        refreshAttachedPatternFileURL()
        refreshAttachedNeedle()
    }

    private func upsertLinkedTool(_ tool: ToolItem) {
        if let index = linkedTools.firstIndex(where: { $0.id == tool.id }) {
            linkedTools[index] = tool
        } else {
            linkedTools.append(tool)
        }

        if let availableIndex = availableTools.firstIndex(where: { $0.id == tool.id }) {
            availableTools[availableIndex] = tool
        } else {
            availableTools.append(tool)
        }

        linkedTools.sort { first, second in
            first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
        availableTools.sort { first, second in
            first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }

    private func upsertProgressPhoto(_ photo: ProjectProgressPhoto) {
        if let index = progressPhotos.firstIndex(where: { $0.id == photo.id }) {
            progressPhotos[index] = photo
        } else {
            progressPhotos.append(photo)
        }

        progressPhotos.sort { first, second in
            if first.takenAt == second.takenAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.takenAt > second.takenAt
        }
    }

    @discardableResult
    private func saveRowInstructions(_ instructions: [RowInstruction]) async -> Bool {
        let sortedInstructions = instructions.sorted { first, second in
            if first.rowNumber == second.rowNumber {
                return first.instructionText.localizedStandardCompare(second.instructionText) == .orderedAscending
            }
            return first.rowNumber < second.rowNumber
        }
        let maxInstructionRow = sortedInstructions.map(\.rowNumber).max()
        let targetRow = max(rowCounter.targetRow ?? 0, maxInstructionRow ?? 0)
        let updatedCounter = makeRowCounter(
            targetRow: targetRow > 0 ? targetRow : nil,
            rowInstructions: sortedInstructions
        )
        let updatedProject = project.copy(rowCounter: updatedCounter)
        return await persist(updatedProject, errorMessage: "행안내를 저장하지 못했어요.")
    }

    private func makeRowCounter(
        mode: RowCounterMode? = nil,
        sectionName: String?? = nil,
        memo: String?? = nil,
        currentRow: Int? = nil,
        targetRow: Int?? = nil,
        rowInstructions: [RowInstruction]? = nil,
        updatedAt: Date = Date()
    ) -> RowCounter {
        let resolvedSectionName: String?
        if let sectionName {
            resolvedSectionName = sectionName
        } else {
            resolvedSectionName = rowCounter.sectionName
        }

        let resolvedMemo: String?
        if let memo {
            resolvedMemo = memo
        } else {
            resolvedMemo = rowCounter.memo
        }

        let resolvedTargetRow: Int?
        if let targetRow {
            resolvedTargetRow = targetRow
        } else {
            resolvedTargetRow = rowCounter.targetRow
        }

        return RowCounter(
            id: rowCounter.id,
            ownerId: rowCounter.ownerId,
            projectId: rowCounter.projectId,
            name: rowCounter.name,
            mode: mode ?? rowCounter.mode,
            sectionName: resolvedSectionName,
            memo: resolvedMemo,
            currentRow: currentRow ?? rowCounter.currentRow,
            targetRow: resolvedTargetRow,
            rowInstructions: rowInstructions ?? rowCounter.rowInstructions,
            createdAt: rowCounter.createdAt,
            updatedAt: updatedAt,
            deletedAt: rowCounter.deletedAt,
            syncStatus: rowCounter.syncStatus
        )
    }

    private func normalizedSkillTags(_ input: String) -> String {
        skillTags(from: input)
            .joined(separator: ",")
    }

    private func skillTags(from input: String) -> [String] {
        input
            .split { character in
                character == "," || character == " " || character == "\n"
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func refreshAttachedPatternFileURL() {
        attachedPatternFileURL = project.patternCopy.flatMap { patternRepository.fileURL(for: $0) }
    }

    private func refreshAttachedNeedle() {
        guard let needleId = project.needleId else {
            attachedNeedle = nil
            return
        }

        attachedNeedle = availableNeedles.first { $0.id == needleId }
    }

    private func upsertGaugeRecord(_ record: GaugeRecord) {
        if let index = gaugeRecords.firstIndex(where: { $0.id == record.id }) {
            gaugeRecords[index] = record
        } else {
            gaugeRecords.append(record)
        }

        gaugeRecords.sort { first, second in
            if first.measuredAt == second.measuredAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.measuredAt > second.measuredAt
        }
    }

    private static func resolvedSheetPosition(for project: KnittingProject) -> ProjectWorkspaceSheetPosition {
        project.workspaceSheetPosition ?? ProjectWorkspaceSheetPosition(displayMode: project.workspaceDisplayMode)
    }

    private func relatedSkillSourceText() async -> String {
        var components: [String] = [
            project.name,
            project.memo,
            memoText
        ]

        components.append(contentsOf: project.workSessions.compactMap(\.memo))
        components.append(contentsOf: rowCounter.rowInstructions.flatMap { instruction in
            [
                instruction.instructionText,
                instruction.skillTags
            ]
        })

        if let patternCopy = project.patternCopy {
            components.append(patternCopy.titleSnapshot)

            if let fileName = patternCopy.fileNameSnapshot {
                components.append(fileName)
            }

            let fileURL = attachedPatternFileURL ?? patternRepository.fileURL(for: patternCopy)
            if let extractedText = await Self.extractText(fromPDFAt: fileURL), !extractedText.isEmpty {
                components.append(extractedText)
            }

            if let sourcePatternDocumentId = patternCopy.sourcePatternDocumentId,
               let sourcePattern = try? await patternRepository.fetchPattern(id: sourcePatternDocumentId) {
                components.append(sourcePattern.title)
                components.append(sourcePattern.notes)
            }
        }

        return components.joined(separator: " ")
    }

    private func patternSkillSuggestionSourceText() async -> String {
        guard let patternCopy = project.patternCopy else {
            return ""
        }

        var components: [String] = [
            patternCopy.titleSnapshot
        ]

        if let fileName = patternCopy.fileNameSnapshot {
            components.append(fileName)
        }

        let fileURL = attachedPatternFileURL ?? patternRepository.fileURL(for: patternCopy)
        if let extractedText = await Self.extractText(fromPDFAt: fileURL), !extractedText.isEmpty {
            components.append(extractedText)
        }

        if let sourcePatternDocumentId = patternCopy.sourcePatternDocumentId,
           let sourcePattern = try? await patternRepository.fetchPattern(id: sourcePatternDocumentId) {
            components.append(sourcePattern.title)
            components.append(sourcePattern.notes)
        }

        return components.joined(separator: "\n")
    }

    nonisolated private static func extractText(fromPDFAt fileURL: URL?) async -> String? {
#if canImport(PDFKit)
        guard let fileURL else {
            return nil
        }

        return await Task.detached(priority: .utility) {
            guard let document = PDFDocument(url: fileURL) else {
                return nil
            }

            let embeddedText = document.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let recognizedText = embeddedText.isEmpty ? recognizeText(in: document) : ""
            let combinedText = [embeddedText, recognizedText]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            return combinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
#else
        return nil
#endif
    }

#if canImport(PDFKit) && canImport(Vision)
    nonisolated private static func recognizeText(in document: PDFDocument) -> String {
        var recognizedTexts: [String] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let cgImage = makeCGImage(for: page) else {
                continue
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]
            request.customWords = knittingOCRCustomWords

            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
                let pageText = request.results?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if !pageText.isEmpty {
                    recognizedTexts.append(pageText)
                }
            } catch {
                continue
            }
        }

        return recognizedTexts.joined(separator: " ")
    }

    nonisolated private static func makeCGImage(for page: PDFPage) -> CGImage? {
#if canImport(UIKit)
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else {
            return nil
        }

        let maxPixelLength: CGFloat = 1_600
        let scale = min(maxPixelLength / bounds.width, maxPixelLength / bounds.height)
        let imageSize = CGSize(
            width: max(1, (bounds.width * scale).rounded()),
            height: max(1, (bounds.height * scale).rounded())
        )

        return page.thumbnail(of: imageSize, for: .mediaBox).cgImage
#else
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else {
            return nil
        }

        let maxPixelLength: CGFloat = 1_600
        let scale = min(maxPixelLength / bounds.width, maxPixelLength / bounds.height)
        let width = max(1, Int((bounds.width * scale).rounded()))
        let height = max(1, Int((bounds.height * scale).rounded()))
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        page.draw(with: .mediaBox, to: context)

        return context.makeImage()
#endif
    }

    nonisolated private static var knittingOCRCustomWords: [String] {
        [
            "K", "P", "RS", "WS", "CO", "BO",
            "YO", "KFB", "PFB", "SSK", "K2TOG", "P2TOG",
            "M1", "M1L", "M1R", "M1LP", "M1RP",
            "SL", "SL1", "WYIF", "WYIB", "PM", "SM", "BOR",
            "CDD", "SK2P", "SSP", "SSSK", "K3TOG",
            "INC", "DEC", "RND", "ST", "STS"
        ]
    }
#else
    nonisolated private static func recognizeText(in document: PDFDocument) -> String {
        ""
    }
#endif

    private static func containsAbbreviation(_ abbreviation: String, in text: String) -> Bool {
        let normalizedAbbreviation = abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !normalizedAbbreviation.isEmpty else {
            return false
        }

        if normalizedAbbreviation.contains(where: \.isWhitespace) {
            return containsSpacedAbbreviation(normalizedAbbreviation, in: text)
        }

        let tokens = text
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return tokens.contains { token in
            if token == normalizedAbbreviation {
                return true
            }

            guard token.hasPrefix(normalizedAbbreviation) else {
                return false
            }

            let suffix = token.dropFirst(normalizedAbbreviation.count)
            return !suffix.isEmpty && suffix.allSatisfy(\.isNumber)
        }
    }

    private static func containsSpacedAbbreviation(_ abbreviation: String, in text: String) -> Bool {
        let parts = abbreviation
            .split { $0.isWhitespace }
            .map(String.init)

        guard !parts.isEmpty else {
            return false
        }

        let escapedParts = parts.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "(?<![A-Z0-9])" + escapedParts.joined(separator: "\\s+") + "(?![A-Z0-9])"
        let range = NSRange(location: 0, length: text.uppercased().utf16.count)

        return (try? NSRegularExpression(pattern: pattern))
            .map { regex in
                regex.firstMatch(in: text.uppercased(), range: range) != nil
            } ?? false
    }

    private static func patternRowInstructionSuggestions(
        from text: String,
        skills: [Skill],
        existingRowNumbers: Set<Int>,
        fallbackStartRow: Int
    ) -> [PatternRowInstructionSuggestion] {
        let lines = patternInstructionCandidateLines(from: text)
        let skillAbbreviations = skills
            .map { $0.abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }

        var usedRowNumbers = existingRowNumbers
        var fallbackRow = max(1, fallbackStartRow)
        var suggestions: [PatternRowInstructionSuggestion] = []

        for line in lines {
            let skillTags = skillAbbreviations.filter { abbreviation in
                containsAbbreviation(abbreviation, in: line)
            }

            guard !skillTags.isEmpty else {
                continue
            }

            let rowNumber = extractRowNumber(from: line) ?? nextAvailableRowNumber(startingAt: &fallbackRow, usedRowNumbers: usedRowNumbers)

            guard rowNumber > 0, !usedRowNumbers.contains(rowNumber) else {
                continue
            }

            usedRowNumbers.insert(rowNumber)
            suggestions.append(
                PatternRowInstructionSuggestion(
                    rowNumber: rowNumber,
                    instructionText: line,
                    skillTags: skillTags
                )
            )
        }

        return suggestions.sorted { first, second in
            if first.rowNumber == second.rowNumber {
                return first.instructionText.localizedStandardCompare(second.instructionText) == .orderedAscending
            }

            return first.rowNumber < second.rowNumber
        }
    }

    private static func patternInstructionCandidateLines(from text: String) -> [String] {
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let newLineCandidates = normalizedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if newLineCandidates.count > 1 {
            return newLineCandidates
        }

        return splitSingleLinePatternText(normalizedText)
    }

    private static func splitSingleLinePatternText(_ text: String) -> [String] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return []
        }

        let markerPattern = #"(?i)\b(?:row|rnd|round|r)\s*[#:\.\-]?\s*\d+\b|\b\d+\s*(?:단|행)\b"#
        let range = NSRange(location: 0, length: trimmedText.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: markerPattern) else {
            return [trimmedText]
        }

        let matches = regex.matches(in: trimmedText, range: range)
        guard matches.count > 1 else {
            return [trimmedText]
        }

        var lines: [String] = []
        for (index, match) in matches.enumerated() {
            let start = match.range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : range.length
            let lineRange = NSRange(location: start, length: max(0, end - start))
            guard let swiftRange = Range(lineRange, in: trimmedText) else {
                continue
            }

            let line = String(trimmedText[swiftRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "·•"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                lines.append(line)
            }
        }

        return lines.isEmpty ? [trimmedText] : lines
    }

    private static func extractRowNumber(from text: String) -> Int? {
        let patterns = [
            #"(?i)\b(?:row|rnd|round|r)\s*[#:\.\-]?\s*(\d+)\b"#,
            #"(?i)\b(\d+)\s*(?:단|행)\b"#
        ]

        for pattern in patterns {
            let range = NSRange(location: 0, length: text.utf16.count)
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let value = Int(text[valueRange]) else {
                continue
            }

            return value
        }

        return nil
    }

    private static func nextAvailableRowNumber(startingAt fallbackRow: inout Int, usedRowNumbers: Set<Int>) -> Int {
        while usedRowNumbers.contains(fallbackRow) {
            fallbackRow += 1
        }

        defer {
            fallbackRow += 1
        }
        return fallbackRow
    }
}
