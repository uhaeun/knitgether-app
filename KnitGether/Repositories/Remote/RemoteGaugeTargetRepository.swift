import Foundation

final class RemoteGaugeTargetRepository: GaugeTargetRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchGaugeTargets() async throws -> [GaugeTarget] {
        try await apiClient.get("gauge-targets")
    }

    func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        let body = SaveGaugeTargetRequest(target: target)
        return try await apiClient.send(
            "gauge-targets",
            method: "POST",
            body: body
        )
    }

    func updateGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        let body = SaveGaugeTargetRequest(target: target)
        return try await apiClient.send(
            "gauge-targets/\(target.id.uuidString.lowercased())",
            method: "PATCH",
            body: body
        )
    }

    func deleteGaugeTarget(id: UUID) async throws {
        try await apiClient.delete("gauge-targets/\(id.uuidString.lowercased())")
    }
}

nonisolated private struct SaveGaugeTargetRequest: Encodable {
    let id: String
    let name: String
    let targetStitches: Double
    let targetWidth: Double
    let targetRows: Double
    let targetHeight: Double
    let isQuickMeasure: Bool
    let gaugeAfterWash: Bool
    let recommendedNeedle: String?
    let sourcePatternId: String?
    let createdAt: Date
    let swatches: [SaveGaugeSwatchRequest]

    init(target: GaugeTarget) {
        id = target.id.uuidString.lowercased()
        name = target.name
        targetStitches = target.targetStitches
        targetWidth = target.targetWidth
        targetRows = target.targetRows
        targetHeight = target.targetHeight
        isQuickMeasure = target.isQuickMeasure
        gaugeAfterWash = target.gaugeAfterWash
        recommendedNeedle = target.recommendedNeedle
        sourcePatternId = target.sourcePatternId?.uuidString.lowercased()
        createdAt = target.createdAt
        swatches = target.swatches.map(SaveGaugeSwatchRequest.init)
    }
}

nonisolated private struct SaveGaugeSwatchRequest: Encodable {
    let id: String
    let isSelected: Bool
    let knittedAt: Date?
    let needleMaterial: String?
    let needleSize: String?
    let needleType: String?
    let notes: String?
    let stitchPattern: String?
    let yarnBrand: String?
    let yarnColor: String?
    let yarnLot: String?
    let yarnName: String?
    let createdAt: Date
    let measurements: [SaveGaugeMeasurementRequest]

    init(swatch: GaugeSwatch) {
        id = swatch.id.uuidString.lowercased()
        isSelected = swatch.isSelected
        knittedAt = swatch.knittedAt
        needleMaterial = swatch.needleMaterial
        needleSize = swatch.needleSize
        needleType = swatch.needleType
        notes = swatch.notes
        stitchPattern = swatch.stitchPattern
        yarnBrand = swatch.yarnBrand
        yarnColor = swatch.yarnColor
        yarnLot = swatch.yarnLot
        yarnName = swatch.yarnName
        createdAt = swatch.createdAt
        measurements = swatch.measurements.map(SaveGaugeMeasurementRequest.init)
    }
}

nonisolated private struct SaveGaugeMeasurementRequest: Encodable {
    let id: String
    let method: String
    let washState: String
    let measuredWidth: Double
    let measuredHeight: Double
    let rawStitches: Double
    let rawRows: Double
    let normalizedStitches: Double
    let normalizedRows: Double
    let finalStitches: Double
    let finalRows: Double
    let autoStitches: Double
    let autoRows: Double
    let autoConfidence: String?
    let userModified: Bool
    let photoPath: String?
    let cornerCoordinates: String?
    let createdAt: Date

    init(measurement: GaugeMeasurement) {
        id = measurement.id.uuidString.lowercased()
        method = measurement.method.rawValue
        washState = measurement.washState.rawValue
        measuredWidth = measurement.measuredWidth
        measuredHeight = measurement.measuredHeight
        rawStitches = measurement.rawStitches
        rawRows = measurement.rawRows
        normalizedStitches = measurement.normalizedStitches
        normalizedRows = measurement.normalizedRows
        finalStitches = measurement.finalStitches
        finalRows = measurement.finalRows
        autoStitches = measurement.autoStitches
        autoRows = measurement.autoRows
        autoConfidence = measurement.autoConfidence
        userModified = measurement.userModified
        photoPath = measurement.photoPath
        cornerCoordinates = measurement.cornerCoordinates
        createdAt = measurement.createdAt
    }
}
