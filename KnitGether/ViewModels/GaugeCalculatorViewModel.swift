//
//  GaugeCalculatorViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import Combine
import Foundation

struct GaugeCalculationResult {
    let stitchesPer10Cm: Double
    let rowsPer10Cm: Double
    let targetStitches: Int
    let targetRows: Int
}

@MainActor
final class GaugeCalculatorViewModel: ObservableObject {
    @Published var sampleWidthCm = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var sampleHeightCm = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var stitchCount = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var rowCount = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var targetWidthCm = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var targetHeightCm = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var needle = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var memo = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published private(set) var selectedPattern: PatternDocument?
    @Published private(set) var manualPatternName = "" {
        didSet { persistInputsIfNeeded() }
    }
    @Published var selectedProject: KnittingProject?
    @Published private(set) var availableProjects: [KnittingProject] = []
    @Published private(set) var availablePatterns: [PatternDocument] = []
    @Published private(set) var gaugeRecords: [GaugeRecord] = []
    @Published private(set) var gaugeTargets: [GaugeTarget] = []
    @Published private(set) var isSavingRecord = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadedGaugeRecordForEditing: GaugeRecord?

    private let gaugeRecordRepository: any GaugeRecordRepository
    private let gaugeTargetRepository: (any GaugeTargetRepository)?
    private let projectRepository: any ProjectRepository
    private let patternRepository: (any PatternRepository)?
    private let userDefaults: UserDefaults
    private var isRestoringInputs = false

    init(
        gaugeRecordRepository: any GaugeRecordRepository,
        gaugeTargetRepository: (any GaugeTargetRepository)? = nil,
        projectRepository: any ProjectRepository,
        patternRepository: (any PatternRepository)? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.gaugeRecordRepository = gaugeRecordRepository
        self.gaugeTargetRepository = gaugeTargetRepository
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.userDefaults = userDefaults
        restoreInputs()
    }

    var hasAnyInput: Bool {
        [
            sampleWidthCm,
            sampleHeightCm,
            stitchCount,
            rowCount,
            targetWidthCm,
            targetHeightCm,
            needle,
            memo,
            manualPatternName
        ]
        .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var result: GaugeCalculationResult? {
        guard
            let sampleWidth = decimalValue(from: sampleWidthCm),
            let sampleHeight = decimalValue(from: sampleHeightCm),
            let stitches = decimalValue(from: stitchCount),
            let rows = decimalValue(from: rowCount),
            let targetWidth = decimalValue(from: targetWidthCm),
            let targetHeight = decimalValue(from: targetHeightCm),
            sampleWidth > 0,
            sampleHeight > 0,
            stitches > 0,
            rows > 0,
            targetWidth > 0,
            targetHeight > 0
        else {
            return nil
        }

        let stitchesPerCm = stitches / sampleWidth
        let rowsPerCm = rows / sampleHeight

        return GaugeCalculationResult(
            stitchesPer10Cm: stitchesPerCm * 10,
            rowsPer10Cm: rowsPerCm * 10,
            targetStitches: Int((stitchesPerCm * targetWidth).rounded()),
            targetRows: Int((rowsPerCm * targetHeight).rounded())
        )
    }

    var washComparison: GaugeWashComparison? {
        let records = filteredRecordsForSelectedProject
        guard
            let before = records
                .filter({ $0.measurementStage == .beforeWash })
                .max(by: { $0.measuredAt < $1.measuredAt }),
            let after = records
                .filter({ $0.measurementStage == .afterWash })
                .max(by: { $0.measuredAt < $1.measuredAt })
        else {
            return nil
        }

        return GaugeWashComparison(before: before, after: after)
    }

    var filteredRecordsForSelectedProject: [GaugeRecord] {
        guard let selectedProject else {
            return gaugeRecords
        }

        return gaugeRecords.filter { $0.projectId == selectedProject.id }
    }

    var patternConnectionSummary: String {
        if let manualPatternName = trimmedManualPatternName {
            return "수동 도안: \(manualPatternName)"
        }

        if let selectedPattern {
            return patternSummary(prefix: "도안 창고", title: selectedPattern.title, fileName: selectedPattern.fileName)
        }

        if let patternCopy = selectedProject?.patternCopy {
            return patternSummary(prefix: "프로젝트 도안", title: patternCopy.titleSnapshot, fileName: patternCopy.fileNameSnapshot)
        }

        return "도안을 연결하지 않고 게이지를 저장할 수 있어요."
    }

    var guidanceMessage: String {
        let requiredInputs = [
            sampleWidthCm,
            sampleHeightCm,
            stitchCount,
            rowCount,
            targetWidthCm,
            targetHeightCm
        ]

        guard requiredInputs.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return "게이지 정보를 입력하면 계산 결과가 표시돼요."
        }

        guard requiredInputs.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return "필수 값을 모두 입력해 주세요."
        }

        guard
            decimalValue(from: sampleWidthCm) != nil,
            decimalValue(from: sampleHeightCm) != nil,
            decimalValue(from: stitchCount) != nil,
            decimalValue(from: rowCount) != nil,
            decimalValue(from: targetWidthCm) != nil,
            decimalValue(from: targetHeightCm) != nil
        else {
            return "숫자를 올바르게 입력해 주세요."
        }

        guard
            (decimalValue(from: sampleWidthCm) ?? 0) > 0,
            (decimalValue(from: sampleHeightCm) ?? 0) > 0
        else {
            return "가로/세로 길이는 0보다 커야 해요."
        }

        guard
            (decimalValue(from: stitchCount) ?? 0) > 0,
            (decimalValue(from: rowCount) ?? 0) > 0
        else {
            return "코 수와 단 수는 0보다 커야 해요."
        }

        guard
            (decimalValue(from: targetWidthCm) ?? 0) > 0,
            (decimalValue(from: targetHeightCm) ?? 0) > 0
        else {
            return "목표 가로/세로는 0보다 커야 해요."
        }

        return "게이지 정보를 입력하면 계산 결과가 표시돼요."
    }

    func reset() {
        isRestoringInputs = true
        sampleWidthCm = ""
        sampleHeightCm = ""
        stitchCount = ""
        rowCount = ""
        targetWidthCm = ""
        targetHeightCm = ""
        needle = ""
        memo = ""
        manualPatternName = ""
        selectedPattern = nil
        loadedGaugeRecordForEditing = nil
        isRestoringInputs = false
        persistInputs()
    }

    func loadProjects() async {
        do {
            availableProjects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트 목록을 불러오지 못했어요."
        }
    }

    func loadGaugeRecords() async {
        do {
            gaugeRecords = try await gaugeRecordRepository.fetchGaugeRecords()
            errorMessage = nil
        } catch {
            errorMessage = "게이지 기록을 불러오지 못했어요."
        }
    }

    func loadGaugeTargets() async {
        guard let gaugeTargetRepository else {
            gaugeTargets = []
            return
        }

        do {
            gaugeTargets = try await gaugeTargetRepository.fetchGaugeTargets()
            errorMessage = nil
        } catch {
            errorMessage = "상세 게이지 측정을 불러오지 못했어요."
        }
    }

    func loadPatterns() async {
        guard let patternRepository else {
            availablePatterns = []
            return
        }

        do {
            availablePatterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안 목록을 불러오지 못했어요."
        }
    }

    func reloadAfterAccountChange() async {
        selectedProject = nil
        selectedPattern = nil
        manualPatternName = ""
        availableProjects = []
        availablePatterns = []
        gaugeRecords = []
        gaugeTargets = []
        loadedGaugeRecordForEditing = nil
        statusMessage = nil
        errorMessage = nil

        do {
            availableProjects = try await projectRepository.fetchProjects()
            if let patternRepository {
                availablePatterns = try await patternRepository.fetchPatterns()
            }
            gaugeRecords = try await gaugeRecordRepository.fetchGaugeRecords()
            if let gaugeTargetRepository {
                gaugeTargets = try await gaugeTargetRepository.fetchGaugeTargets()
            }
            errorMessage = nil
        } catch {
            availableProjects = []
            availablePatterns = []
            gaugeRecords = []
            gaugeTargets = []
            errorMessage = "계정 데이터를 다시 불러오지 못했어요."
        }
    }

    func selectPattern(_ pattern: PatternDocument?) {
        selectedPattern = pattern

        if pattern != nil {
            setManualPatternName("")
        }
    }

    func setManualPatternName(_ name: String) {
        manualPatternName = name

        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectedPattern = nil
        }
    }

    func saveCurrentGaugeRecord(stage: GaugeMeasurementStage) async {
        guard
            let result,
            let sampleWidth = decimalValue(from: sampleWidthCm),
            let sampleHeight = decimalValue(from: sampleHeightCm),
            let stitches = decimalValue(from: stitchCount),
            let rows = decimalValue(from: rowCount),
            let targetWidth = decimalValue(from: targetWidthCm),
            let targetHeight = decimalValue(from: targetHeightCm)
        else {
            errorMessage = guidanceMessage
            return
        }

        isSavingRecord = true
        defer { isSavingRecord = false }

        let now = Date()
        let record = GaugeRecord(
            ownerId: selectedProject?.ownerId,
            projectId: selectedProject?.id,
            projectNameSnapshot: selectedProject?.name,
            patternNameSnapshot: effectivePatternNameSnapshot,
            measurementStage: stage,
            sampleWidthCm: sampleWidth,
            sampleHeightCm: sampleHeight,
            stitchCount: stitches,
            rowCount: rows,
            targetWidthCm: targetWidth,
            targetHeightCm: targetHeight,
            stitchesPer10Cm: result.stitchesPer10Cm,
            rowsPer10Cm: result.rowsPer10Cm,
            targetStitches: result.targetStitches,
            targetRows: result.targetRows,
            needle: needle,
            memo: memo,
            measuredAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )

        do {
            let saved = try await gaugeRecordRepository.saveGaugeRecord(record)
            upsertRecord(saved)
            statusMessage = "\(stage.title) 게이지를 저장했어요."
            loadedGaugeRecordForEditing = nil
            errorMessage = nil
        } catch {
            errorMessage = "게이지 기록을 저장하지 못했어요."
        }
    }

    func updateLoadedGaugeRecord() async {
        guard let loadedGaugeRecordForEditing else {
            errorMessage = "수정할 게이지 기록을 먼저 불러와 주세요."
            return
        }

        guard
            let result,
            let sampleWidth = decimalValue(from: sampleWidthCm),
            let sampleHeight = decimalValue(from: sampleHeightCm),
            let stitches = decimalValue(from: stitchCount),
            let rows = decimalValue(from: rowCount),
            let targetWidth = decimalValue(from: targetWidthCm),
            let targetHeight = decimalValue(from: targetHeightCm)
        else {
            errorMessage = guidanceMessage
            return
        }

        isSavingRecord = true
        defer { isSavingRecord = false }

        let updatedRecord = GaugeRecord(
            id: loadedGaugeRecordForEditing.id,
            ownerId: loadedGaugeRecordForEditing.ownerId ?? selectedProject?.ownerId,
            projectId: selectedProject?.id,
            projectNameSnapshot: selectedProject?.name,
            patternNameSnapshot: effectivePatternNameSnapshot,
            measurementStage: loadedGaugeRecordForEditing.measurementStage,
            sampleWidthCm: sampleWidth,
            sampleHeightCm: sampleHeight,
            stitchCount: stitches,
            rowCount: rows,
            targetWidthCm: targetWidth,
            targetHeightCm: targetHeight,
            stitchesPer10Cm: result.stitchesPer10Cm,
            rowsPer10Cm: result.rowsPer10Cm,
            targetStitches: result.targetStitches,
            targetRows: result.targetRows,
            needle: needle,
            memo: memo,
            measuredAt: loadedGaugeRecordForEditing.measuredAt,
            createdAt: loadedGaugeRecordForEditing.createdAt,
            updatedAt: Date(),
            deletedAt: loadedGaugeRecordForEditing.deletedAt,
            syncStatus: mutationSyncStatus(for: loadedGaugeRecordForEditing.syncStatus)
        )

        do {
            let saved = try await gaugeRecordRepository.updateGaugeRecord(updatedRecord)
            upsertRecord(saved)
            self.loadedGaugeRecordForEditing = saved
            statusMessage = "\(saved.measurementStage.title) 게이지 기록을 수정했어요."
            errorMessage = nil
        } catch {
            errorMessage = "게이지 기록을 수정하지 못했어요."
        }
    }

    func saveCurrentGaugeTarget(washState: GaugeWashState) async {
        guard let gaugeTargetRepository else {
            errorMessage = "상세 게이지 저장소가 연결되지 않았어요."
            return
        }

        guard
            let result,
            let sampleWidth = decimalValue(from: sampleWidthCm),
            let sampleHeight = decimalValue(from: sampleHeightCm),
            let stitches = decimalValue(from: stitchCount),
            let rows = decimalValue(from: rowCount)
        else {
            errorMessage = guidanceMessage
            return
        }

        isSavingRecord = true
        defer { isSavingRecord = false }

        let now = Date()
        let targetId = UUID()
        let swatchId = UUID()
        let measurement = GaugeMeasurement(
            ownerId: selectedProject?.ownerId,
            gaugeTargetId: targetId,
            gaugeSwatchId: swatchId,
            method: .manual,
            washState: washState,
            measuredWidth: sampleWidth,
            measuredHeight: sampleHeight,
            rawStitches: stitches,
            rawRows: rows,
            normalizedStitches: result.stitchesPer10Cm,
            normalizedRows: result.rowsPer10Cm,
            finalStitches: result.stitchesPer10Cm,
            finalRows: result.rowsPer10Cm,
            autoStitches: 0,
            autoRows: 0,
            autoConfidence: nil,
            userModified: false,
            photoPath: nil,
            cornerCoordinates: nil,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let swatch = GaugeSwatch(
            id: swatchId,
            ownerId: selectedProject?.ownerId,
            gaugeTargetId: targetId,
            isSelected: true,
            knittedAt: now,
            needleMaterial: nil,
            needleSize: trimmedNeedle,
            needleType: nil,
            notes: trimmedMemo,
            stitchPattern: nil,
            yarnBrand: nil,
            yarnColor: nil,
            yarnLot: nil,
            yarnName: nil,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly,
            measurements: [measurement]
        )
        let target = GaugeTarget(
            id: targetId,
            ownerId: selectedProject?.ownerId,
            name: "\(effectiveGaugeTargetName) 게이지",
            targetStitches: stitches,
            targetWidth: sampleWidth,
            targetRows: rows,
            targetHeight: sampleHeight,
            isQuickMeasure: false,
            gaugeAfterWash: washState == .after,
            recommendedNeedle: trimmedNeedle,
            sourcePatternId: selectedPattern?.id ?? selectedProject?.patternCopy?.sourcePatternDocumentId,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly,
            swatches: [swatch]
        )

        do {
            let saved = try await gaugeTargetRepository.saveGaugeTarget(target)
            upsertGaugeTarget(saved)
            statusMessage = "상세 게이지 측정을 저장했어요."
            errorMessage = nil
        } catch {
            errorMessage = "상세 게이지 측정을 저장하지 못했어요."
        }
    }

    func deleteGaugeRecord(id: UUID) async {
        do {
            try await gaugeRecordRepository.deleteGaugeRecord(id: id)
            gaugeRecords.removeAll { $0.id == id }
            errorMessage = nil
        } catch {
            errorMessage = "게이지 기록을 삭제하지 못했어요."
        }
    }

    func loadGaugeRecord(_ record: GaugeRecord) {
        isRestoringInputs = true
        sampleWidthCm = inputText(from: record.sampleWidthCm)
        sampleHeightCm = inputText(from: record.sampleHeightCm)
        stitchCount = inputText(from: record.stitchCount)
        rowCount = inputText(from: record.rowCount)
        targetWidthCm = inputText(from: record.targetWidthCm)
        targetHeightCm = inputText(from: record.targetHeightCm)
        needle = record.needle
        memo = record.memo
        manualPatternName = ""
        selectedPattern = nil
        loadedGaugeRecordForEditing = record
        isRestoringInputs = false
        persistInputs()

        selectedProject = record.projectId.flatMap { projectId in
            availableProjects.first { $0.id == projectId }
        }

        let projectPatternName = selectedProject?.patternCopy?.titleSnapshot
        let loadedPatternName = record.patternNameSnapshot?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let loadedPatternName, !loadedPatternName.isEmpty, loadedPatternName != projectPatternName {
            if let matchedPattern = availablePatterns.first(where: { $0.title == loadedPatternName }) {
                selectedPattern = matchedPattern
            } else {
                manualPatternName = loadedPatternName
            }
        }

        statusMessage = "\(record.measurementStage.title) 게이지를 불러왔어요."
        errorMessage = nil
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    private func decimalValue(from text: String) -> Double? {
        let normalizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalizedText.isEmpty else {
            return nil
        }

        return Double(normalizedText)
    }

    private func inputText(from value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }

    private func upsertRecord(_ record: GaugeRecord) {
        if let index = gaugeRecords.firstIndex(where: { $0.id == record.id }) {
            gaugeRecords[index] = record
        } else {
            gaugeRecords.insert(record, at: 0)
        }

        gaugeRecords.sort { $0.measuredAt > $1.measuredAt }
    }

    private func upsertGaugeTarget(_ target: GaugeTarget) {
        if let index = gaugeTargets.firstIndex(where: { $0.id == target.id }) {
            gaugeTargets[index] = target
        } else {
            gaugeTargets.insert(target, at: 0)
        }

        gaugeTargets.sort { $0.createdAt > $1.createdAt }
    }

    private var trimmedManualPatternName: String? {
        let name = manualPatternName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    private var effectivePatternNameSnapshot: String? {
        if let trimmedManualPatternName {
            return trimmedManualPatternName
        }

        if let selectedPattern {
            return selectedPattern.title
        }

        return selectedProject?.patternCopy?.titleSnapshot
    }

    private var effectiveGaugeTargetName: String {
        if let effectivePatternNameSnapshot,
           !effectivePatternNameSnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return effectivePatternNameSnapshot
        }

        if let selectedProject {
            return selectedProject.name
        }

        return "게이지 측정"
    }

    private var trimmedNeedle: String? {
        let value = needle.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var trimmedMemo: String? {
        let value = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func patternSummary(prefix: String, title: String, fileName: String?) -> String {
        guard let fileName, !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "\(prefix): \(title)"
        }

        return "\(prefix): \(title) · \(fileName)"
    }

    private func mutationSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        syncStatus == .synced ? .pendingUpload : syncStatus
    }

    private func restoreInputs() {
        isRestoringInputs = true
        sampleWidthCm = userDefaults.string(forKey: StorageKey.sampleWidthCm) ?? ""
        sampleHeightCm = userDefaults.string(forKey: StorageKey.sampleHeightCm) ?? ""
        stitchCount = userDefaults.string(forKey: StorageKey.stitchCount) ?? ""
        rowCount = userDefaults.string(forKey: StorageKey.rowCount) ?? ""
        targetWidthCm = userDefaults.string(forKey: StorageKey.targetWidthCm) ?? ""
        targetHeightCm = userDefaults.string(forKey: StorageKey.targetHeightCm) ?? ""
        needle = userDefaults.string(forKey: StorageKey.needle) ?? ""
        memo = userDefaults.string(forKey: StorageKey.memo) ?? ""
        manualPatternName = userDefaults.string(forKey: StorageKey.manualPatternName) ?? ""
        isRestoringInputs = false
    }

    private func persistInputsIfNeeded() {
        guard !isRestoringInputs else {
            return
        }

        persistInputs()
    }

    private func persistInputs() {
        userDefaults.set(sampleWidthCm, forKey: StorageKey.sampleWidthCm)
        userDefaults.set(sampleHeightCm, forKey: StorageKey.sampleHeightCm)
        userDefaults.set(stitchCount, forKey: StorageKey.stitchCount)
        userDefaults.set(rowCount, forKey: StorageKey.rowCount)
        userDefaults.set(targetWidthCm, forKey: StorageKey.targetWidthCm)
        userDefaults.set(targetHeightCm, forKey: StorageKey.targetHeightCm)
        userDefaults.set(needle, forKey: StorageKey.needle)
        userDefaults.set(memo, forKey: StorageKey.memo)
        userDefaults.set(manualPatternName, forKey: StorageKey.manualPatternName)
    }

    private enum StorageKey {
        static let sampleWidthCm = "GaugeCalculator.sampleWidthCm"
        static let sampleHeightCm = "GaugeCalculator.sampleHeightCm"
        static let stitchCount = "GaugeCalculator.stitchCount"
        static let rowCount = "GaugeCalculator.rowCount"
        static let targetWidthCm = "GaugeCalculator.targetWidthCm"
        static let targetHeightCm = "GaugeCalculator.targetHeightCm"
        static let needle = "GaugeCalculator.needle"
        static let memo = "GaugeCalculator.memo"
        static let manualPatternName = "GaugeCalculator.manualPatternName"
    }
}
