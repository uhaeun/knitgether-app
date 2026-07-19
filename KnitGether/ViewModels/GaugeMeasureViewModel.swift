import Combine
import Foundation

struct GaugeTargetFormData: Equatable {
    var name: String
    var width: String
    var height: String
    var stitches: String
    var rows: String
    var recommendedNeedle: String
    var gaugeAfterWash: Bool
    var sourcePatternId: UUID?

    init(
        name: String = "",
        width: String = "",
        height: String = "",
        stitches: String = "",
        rows: String = "",
        recommendedNeedle: String = "",
        gaugeAfterWash: Bool = false,
        sourcePatternId: UUID? = nil
    ) {
        self.name = name
        self.width = width
        self.height = height
        self.stitches = stitches
        self.rows = rows
        self.recommendedNeedle = recommendedNeedle
        self.gaugeAfterWash = gaugeAfterWash
        self.sourcePatternId = sourcePatternId
    }

    init(target: GaugeTarget) {
        self.init(
            name: target.name,
            width: Self.inputText(from: target.targetWidth),
            height: Self.inputText(from: target.targetHeight),
            stitches: Self.inputText(from: target.targetStitches),
            rows: Self.inputText(from: target.targetRows),
            recommendedNeedle: target.recommendedNeedle ?? "",
            gaugeAfterWash: target.gaugeAfterWash,
            sourcePatternId: target.sourcePatternId
        )
    }

    private static func inputText(from value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}

struct GaugeSwatchFormData: Equatable {
    var needleSize: String
    var needleType: String
    var needleMaterial: String
    var yarnName: String
    var yarnBrand: String
    var yarnColor: String
    var yarnLot: String
    var stitchPattern: String
    var notes: String

    init(
        needleSize: String = "",
        needleType: String = "",
        needleMaterial: String = "",
        yarnName: String = "",
        yarnBrand: String = "",
        yarnColor: String = "",
        yarnLot: String = "",
        stitchPattern: String = "",
        notes: String = ""
    ) {
        self.needleSize = needleSize
        self.needleType = needleType
        self.needleMaterial = needleMaterial
        self.yarnName = yarnName
        self.yarnBrand = yarnBrand
        self.yarnColor = yarnColor
        self.yarnLot = yarnLot
        self.stitchPattern = stitchPattern
        self.notes = notes
    }

    init(swatch: GaugeSwatch) {
        self.init(
            needleSize: swatch.needleSize ?? "",
            needleType: swatch.needleType ?? "",
            needleMaterial: swatch.needleMaterial ?? "",
            yarnName: swatch.yarnName ?? "",
            yarnBrand: swatch.yarnBrand ?? "",
            yarnColor: swatch.yarnColor ?? "",
            yarnLot: swatch.yarnLot ?? "",
            stitchPattern: swatch.stitchPattern ?? "",
            notes: swatch.notes ?? ""
        )
    }
}

struct GaugeMeasurementFormData: Equatable {
    var stitches: String
    var rows: String
    var width: String
    var height: String
    var washState: GaugeWashState

    init(
        stitches: String = "",
        rows: String = "",
        width: String = "",
        height: String = "",
        washState: GaugeWashState = .before
    ) {
        self.stitches = stitches
        self.rows = rows
        self.width = width
        self.height = height
        self.washState = washState
    }

    init(measurement: GaugeMeasurement) {
        self.init(
            stitches: Self.inputText(from: measurement.rawStitches),
            rows: Self.inputText(from: measurement.rawRows),
            width: Self.inputText(from: measurement.measuredWidth),
            height: Self.inputText(from: measurement.measuredHeight),
            washState: measurement.washState
        )
    }

    var input: ManualMeasurementInput {
        ManualMeasurementInput(stitches: stitches, rows: rows, width: width, height: height)
    }

    private static func inputText(from value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}

@MainActor
final class GaugeMeasureViewModel: ObservableObject {
    @Published private(set) var targets: [GaugeTarget] = []
    @Published var targetForm = GaugeTargetFormData()
    @Published var swatchForm = GaugeSwatchFormData()
    @Published var measurementForm = GaugeMeasurementFormData()
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?

    private let repository: any GaugeTargetRepository

    init(repository: any GaugeTargetRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            targets = try await repository.fetchGaugeTargets()
                .sorted { $0.updatedAt > $1.updatedAt }
            errorMessage = nil
        } catch {
            errorMessage = "게이지 측정 목록을 불러오지 못했어요."
            statusMessage = nil
        }
    }

    func prepareTargetForm(for target: GaugeTarget?) {
        targetForm = target.map(GaugeTargetFormData.init) ?? GaugeTargetFormData()
    }

    func prepareSwatchForm(for swatch: GaugeSwatch?) {
        swatchForm = swatch.map(GaugeSwatchFormData.init) ?? GaugeSwatchFormData()
    }

    func prepareMeasurementForm(for measurement: GaugeMeasurement?) {
        measurementForm = measurement.map(GaugeMeasurementFormData.init) ?? GaugeMeasurementFormData()
    }

    func clearError() {
        errorMessage = nil
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    @discardableResult
    func saveTarget(existingID: UUID? = nil) async -> Bool {
        guard let validated = GaugeTargetInput(
            name: targetForm.name,
            width: targetForm.width,
            height: targetForm.height,
            stitches: targetForm.stitches,
            rows: targetForm.rows
        ).validated else {
            errorMessage = "목표 게이지 값을 올바르게 입력해 주세요."
            statusMessage = nil
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let existingTarget = existingID.flatMap(target)
        let targetToSave = GaugeTarget(
            id: existingTarget?.id ?? UUID(),
            ownerId: existingTarget?.ownerId,
            name: validated.name,
            targetStitches: validated.stitches,
            targetWidth: validated.width,
            targetRows: validated.rows,
            targetHeight: validated.height,
            isQuickMeasure: existingTarget?.isQuickMeasure ?? false,
            gaugeAfterWash: targetForm.gaugeAfterWash,
            recommendedNeedle: trimmedOptional(targetForm.recommendedNeedle),
            sourcePatternId: targetForm.sourcePatternId ?? existingTarget?.sourcePatternId,
            createdAt: existingTarget?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingTarget?.deletedAt,
            syncStatus: .localOnly,
            swatches: existingTarget?.swatches ?? []
        )

        do {
            let saved: GaugeTarget
            if existingTarget == nil {
                saved = try await repository.saveGaugeTarget(targetToSave)
            } else {
                saved = try await repository.updateGaugeTarget(targetToSave)
            }
            upsert(saved)
            targetForm = GaugeTargetFormData()
            statusMessage = "목표 게이지를 저장했어요."
            errorMessage = nil
            return true
        } catch {
            errorMessage = "목표 게이지를 저장하지 못했어요."
            statusMessage = nil
            return false
        }
    }

    @discardableResult
    func saveSwatch(targetID: UUID, existingSwatchID: UUID? = nil) async -> Bool {
        guard let existingTarget = target(id: targetID) else {
            errorMessage = "목표 게이지를 찾지 못했어요."
            statusMessage = nil
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let existingSwatch = existingSwatchID.flatMap { swatch(id: $0, in: existingTarget) }
        let swatchToSave = GaugeSwatch(
            id: existingSwatch?.id ?? UUID(),
            ownerId: existingTarget.ownerId,
            gaugeTargetId: existingTarget.id,
            isSelected: existingSwatch?.isSelected ?? existingTarget.swatches.isEmpty,
            knittedAt: existingSwatch?.knittedAt ?? now,
            needleMaterial: trimmedOptional(swatchForm.needleMaterial),
            needleSize: trimmedOptional(swatchForm.needleSize),
            needleType: trimmedOptional(swatchForm.needleType),
            notes: trimmedOptional(swatchForm.notes),
            stitchPattern: trimmedOptional(swatchForm.stitchPattern),
            yarnBrand: trimmedOptional(swatchForm.yarnBrand),
            yarnColor: trimmedOptional(swatchForm.yarnColor),
            yarnLot: trimmedOptional(swatchForm.yarnLot),
            yarnName: trimmedOptional(swatchForm.yarnName),
            createdAt: existingSwatch?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingSwatch?.deletedAt,
            syncStatus: .localOnly,
            measurements: existingSwatch?.measurements ?? []
        )

        var swatches = existingTarget.swatches
        replaceOrAppend(&swatches, swatchToSave)

        return await saveUpdatedTarget(
            copy(existingTarget, updatedAt: now, swatches: swatches),
            successMessage: "스와치를 저장했어요.",
            failureMessage: "스와치를 저장하지 못했어요."
        )
    }

    @discardableResult
    func deleteTarget(id: UUID) async -> Bool {
        do {
            try await repository.deleteGaugeTarget(id: id)
            targets.removeAll { $0.id == id }
            errorMessage = nil
            statusMessage = "목표 게이지를 삭제했어요."
            return true
        } catch {
            errorMessage = "목표 게이지를 삭제하지 못했어요."
            statusMessage = nil
            return false
        }
    }

    @discardableResult
    func saveManualMeasurement(
        targetID: UUID,
        swatchID: UUID,
        washState: GaugeWashState,
        input: ManualMeasurementInput,
        existingMeasurementID: UUID? = nil
    ) async -> Bool {
        guard
            let existingTarget = target(id: targetID),
            let existingSwatch = swatch(id: swatchID, in: existingTarget),
            let normalized = input.normalized,
            let measuredWidth = decimalValue(from: input.width),
            let measuredHeight = decimalValue(from: input.height),
            let rawStitches = decimalValue(from: input.stitches)
        else {
            errorMessage = "측정 값을 올바르게 입력해 주세요."
            statusMessage = nil
            return false
        }

        let rawRows = decimalValue(from: input.rows) ?? 0

        return await saveMeasurement(
            target: existingTarget,
            swatch: existingSwatch,
            existingMeasurementID: existingMeasurementID,
            method: .manual,
            washState: washState,
            measuredWidth: measuredWidth,
            measuredHeight: measuredHeight,
            rawStitches: rawStitches,
            rawRows: rawRows,
            normalizedStitches: normalized.stitchesPer10cm,
            normalizedRows: normalized.rowsPer10cm,
            finalStitches: normalized.stitchesPer10cm,
            finalRows: normalized.rowsPer10cm,
            autoStitches: 0,
            autoRows: 0,
            autoConfidence: nil,
            userModified: existingMeasurementID != nil,
            photoPath: nil,
            cornerCoordinates: nil
        )
    }

    @discardableResult
    func savePhotoMeasurement(
        targetID: UUID,
        swatchID: UUID,
        washState: GaugeWashState,
        measuredWidth: Double,
        measuredHeight: Double,
        autoResult: GaugeAutoCountResult,
        correctedStitches: Double? = nil,
        correctedRows: Double? = nil,
        cornerCoordinates: String?
    ) async -> Bool {
        guard
            measuredWidth > 0,
            measuredHeight > 0,
            let existingTarget = target(id: targetID),
            let existingSwatch = swatch(id: swatchID, in: existingTarget)
        else {
            errorMessage = "사진 측정 값을 올바르게 입력해 주세요."
            statusMessage = nil
            return false
        }

        let rawStitches = correctedStitches ?? autoResult.stitches
        let rawRows = correctedRows ?? autoResult.rows
        let normalizedStitches = rawStitches / measuredWidth * 10
        let normalizedRows = rawRows / measuredHeight * 10
        let userModified = abs(rawStitches - autoResult.stitches) > 0.001
            || abs(rawRows - autoResult.rows) > 0.001

        return await saveMeasurement(
            target: existingTarget,
            swatch: existingSwatch,
            existingMeasurementID: nil,
            method: .photo4pt,
            washState: washState,
            measuredWidth: measuredWidth,
            measuredHeight: measuredHeight,
            rawStitches: rawStitches,
            rawRows: rawRows,
            normalizedStitches: normalizedStitches,
            normalizedRows: normalizedRows,
            finalStitches: normalizedStitches,
            finalRows: normalizedRows,
            autoStitches: autoResult.stitches,
            autoRows: autoResult.rows,
            autoConfidence: autoResult.confidence.rawValue,
            userModified: userModified,
            photoPath: nil,
            cornerCoordinates: cornerCoordinates
        )
    }

    func target(id: UUID) -> GaugeTarget? {
        targets.first { $0.id == id }
    }

    func swatch(id: UUID, in target: GaugeTarget) -> GaugeSwatch? {
        target.swatches.first { $0.id == id }
    }

    private func saveMeasurement(
        target: GaugeTarget,
        swatch: GaugeSwatch,
        existingMeasurementID: UUID?,
        method: GaugeMeasurementMethod,
        washState: GaugeWashState,
        measuredWidth: Double,
        measuredHeight: Double,
        rawStitches: Double,
        rawRows: Double,
        normalizedStitches: Double,
        normalizedRows: Double,
        finalStitches: Double,
        finalRows: Double,
        autoStitches: Double,
        autoRows: Double,
        autoConfidence: String?,
        userModified: Bool,
        photoPath: String?,
        cornerCoordinates: String?
    ) async -> Bool {
        let now = Date()
        let existingMeasurement = existingMeasurementID.flatMap { measurement(id: $0, in: swatch) }
        let measurementToSave = GaugeMeasurement(
            id: existingMeasurement?.id ?? UUID(),
            ownerId: target.ownerId,
            gaugeTargetId: target.id,
            gaugeSwatchId: swatch.id,
            method: method,
            washState: washState,
            measuredWidth: measuredWidth,
            measuredHeight: measuredHeight,
            rawStitches: rawStitches,
            rawRows: rawRows,
            normalizedStitches: normalizedStitches,
            normalizedRows: normalizedRows,
            finalStitches: finalStitches,
            finalRows: finalRows,
            autoStitches: autoStitches,
            autoRows: autoRows,
            autoConfidence: autoConfidence,
            userModified: userModified,
            photoPath: photoPath,
            cornerCoordinates: cornerCoordinates,
            createdAt: existingMeasurement?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingMeasurement?.deletedAt,
            syncStatus: .localOnly
        )

        var measurements = swatch.measurements
        replaceOrAppend(&measurements, measurementToSave)
        var swatches = target.swatches
        replaceOrAppend(
            &swatches,
            copy(swatch, updatedAt: now, measurements: measurements)
        )

        return await saveUpdatedTarget(
            copy(
                target,
                updatedAt: now,
                gaugeAfterWash: target.gaugeAfterWash || washState == .after,
                swatches: swatches
            ),
            successMessage: "측정값을 저장했어요.",
            failureMessage: "측정값을 저장하지 못했어요."
        )
    }

    private func measurement(id: UUID, in swatch: GaugeSwatch) -> GaugeMeasurement? {
        swatch.measurements.first { $0.id == id }
    }

    private func saveUpdatedTarget(
        _ target: GaugeTarget,
        successMessage: String,
        failureMessage: String
    ) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        do {
            let saved = try await repository.updateGaugeTarget(target)
            upsert(saved)
            swatchForm = GaugeSwatchFormData()
            measurementForm = GaugeMeasurementFormData()
            statusMessage = successMessage
            errorMessage = nil
            return true
        } catch {
            errorMessage = failureMessage
            statusMessage = nil
            return false
        }
    }

    private func upsert(_ target: GaugeTarget) {
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            targets[index] = target
        } else {
            targets.insert(target, at: 0)
        }

        targets.sort { $0.updatedAt > $1.updatedAt }
    }

    private func replaceOrAppend<T: Identifiable>(_ values: inout [T], _ value: T) where T.ID == UUID {
        if let index = values.firstIndex(where: { $0.id == value.id }) {
            values[index] = value
        } else {
            values.append(value)
        }
    }

    private func copy(
        _ target: GaugeTarget,
        updatedAt: Date,
        gaugeAfterWash: Bool? = nil,
        swatches: [GaugeSwatch]
    ) -> GaugeTarget {
        GaugeTarget(
            id: target.id,
            ownerId: target.ownerId,
            name: target.name,
            targetStitches: target.targetStitches,
            targetWidth: target.targetWidth,
            targetRows: target.targetRows,
            targetHeight: target.targetHeight,
            isQuickMeasure: target.isQuickMeasure,
            gaugeAfterWash: gaugeAfterWash ?? target.gaugeAfterWash,
            recommendedNeedle: target.recommendedNeedle,
            sourcePatternId: target.sourcePatternId,
            createdAt: target.createdAt,
            updatedAt: updatedAt,
            deletedAt: target.deletedAt,
            syncStatus: .localOnly,
            swatches: swatches
        )
    }

    private func copy(
        _ swatch: GaugeSwatch,
        updatedAt: Date,
        measurements: [GaugeMeasurement]
    ) -> GaugeSwatch {
        GaugeSwatch(
            id: swatch.id,
            ownerId: swatch.ownerId,
            gaugeTargetId: swatch.gaugeTargetId,
            isSelected: swatch.isSelected,
            knittedAt: swatch.knittedAt,
            needleMaterial: swatch.needleMaterial,
            needleSize: swatch.needleSize,
            needleType: swatch.needleType,
            notes: swatch.notes,
            stitchPattern: swatch.stitchPattern,
            yarnBrand: swatch.yarnBrand,
            yarnColor: swatch.yarnColor,
            yarnLot: swatch.yarnLot,
            yarnName: swatch.yarnName,
            createdAt: swatch.createdAt,
            updatedAt: updatedAt,
            deletedAt: swatch.deletedAt,
            syncStatus: .localOnly,
            measurements: measurements
        )
    }

    private func trimmedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func decimalValue(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else {
            return nil
        }

        return Double(normalized)
    }
}
