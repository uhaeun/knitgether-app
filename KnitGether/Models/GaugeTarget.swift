import Foundation

enum GaugeMeasurementMethod: String, CaseIterable, Codable, Identifiable, Hashable {
    case manual
    case photo4pt
    case marker
    case ar

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .manual:
            "직접 측정"
        case .photo4pt:
            "사진 4점"
        case .marker:
            "마커"
        case .ar:
            "AR 카메라"
        }
    }
}

enum GaugeWashState: String, CaseIterable, Codable, Identifiable, Hashable {
    case before
    case after

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .before:
            "세탁 전"
        case .after:
            "세탁 후"
        }
    }
}

struct GaugeMeasurement: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let gaugeTargetId: UUID
    let gaugeSwatchId: UUID
    let method: GaugeMeasurementMethod
    let washState: GaugeWashState
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
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        gaugeTargetId: UUID,
        gaugeSwatchId: UUID,
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
        autoStitches: Double = 0,
        autoRows: Double = 0,
        autoConfidence: String? = nil,
        userModified: Bool = false,
        photoPath: String? = nil,
        cornerCoordinates: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.gaugeTargetId = gaugeTargetId
        self.gaugeSwatchId = gaugeSwatchId
        self.method = method
        self.washState = washState
        self.measuredWidth = measuredWidth
        self.measuredHeight = measuredHeight
        self.rawStitches = rawStitches
        self.rawRows = rawRows
        self.normalizedStitches = normalizedStitches
        self.normalizedRows = normalizedRows
        self.finalStitches = finalStitches
        self.finalRows = finalRows
        self.autoStitches = autoStitches
        self.autoRows = autoRows
        self.autoConfidence = autoConfidence
        self.userModified = userModified
        self.photoPath = photoPath
        self.cornerCoordinates = cornerCoordinates
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }
}

struct GaugeSwatch: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let gaugeTargetId: UUID
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
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
    let measurements: [GaugeMeasurement]

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        gaugeTargetId: UUID,
        isSelected: Bool = false,
        knittedAt: Date? = nil,
        needleMaterial: String? = nil,
        needleSize: String? = nil,
        needleType: String? = nil,
        notes: String? = nil,
        stitchPattern: String? = nil,
        yarnBrand: String? = nil,
        yarnColor: String? = nil,
        yarnLot: String? = nil,
        yarnName: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly,
        measurements: [GaugeMeasurement] = []
    ) {
        self.id = id
        self.ownerId = ownerId
        self.gaugeTargetId = gaugeTargetId
        self.isSelected = isSelected
        self.knittedAt = knittedAt
        self.needleMaterial = needleMaterial
        self.needleSize = needleSize
        self.needleType = needleType
        self.notes = notes
        self.stitchPattern = stitchPattern
        self.yarnBrand = yarnBrand
        self.yarnColor = yarnColor
        self.yarnLot = yarnLot
        self.yarnName = yarnName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
        self.measurements = measurements
    }

    var beforeWashMeasurement: GaugeMeasurement? {
        measurements.first { $0.washState == .before }
    }

    var afterWashMeasurement: GaugeMeasurement? {
        measurements.first { $0.washState == .after }
    }
}

struct GaugeTarget: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let targetStitches: Double
    let targetWidth: Double
    let targetRows: Double
    let targetHeight: Double
    let isQuickMeasure: Bool
    let gaugeAfterWash: Bool
    let recommendedNeedle: String?
    let sourcePatternId: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
    let swatches: [GaugeSwatch]

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        name: String,
        targetStitches: Double,
        targetWidth: Double,
        targetRows: Double = 0,
        targetHeight: Double = 0,
        isQuickMeasure: Bool = false,
        gaugeAfterWash: Bool = false,
        recommendedNeedle: String? = nil,
        sourcePatternId: UUID? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly,
        swatches: [GaugeSwatch] = []
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.targetStitches = targetStitches
        self.targetWidth = targetWidth
        self.targetRows = targetRows
        self.targetHeight = targetHeight
        self.isQuickMeasure = isQuickMeasure
        self.gaugeAfterWash = gaugeAfterWash
        self.recommendedNeedle = recommendedNeedle
        self.sourcePatternId = sourcePatternId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
        self.swatches = swatches
    }

    var targetStitchesPer10Cm: Double {
        guard targetWidth > 0 else {
            return targetStitches
        }

        return targetStitches / targetWidth * 10
    }

    var targetRowsPer10Cm: Double? {
        guard targetRows > 0 else {
            return nil
        }

        guard targetHeight > 0 else {
            return targetRows
        }

        return targetRows / targetHeight * 10
    }
}
