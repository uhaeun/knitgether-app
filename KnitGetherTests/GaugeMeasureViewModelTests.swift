import Foundation
import Testing
@testable import KnitGether

@MainActor
struct GaugeMeasureViewModelTests {
    @Test func saveTargetCreatesTrimmedGaugeTarget() async throws {
        let repository = GaugeTargetRepositorySpy()
        let viewModel = GaugeMeasureViewModel(repository: repository)

        viewModel.targetForm = GaugeTargetFormData(
            name: "  Cable Vest  ",
            width: "10",
            height: "10",
            stitches: "22",
            rows: "30",
            recommendedNeedle: " 4.0 mm "
        )

        let saved = await viewModel.saveTarget()

        #expect(saved == true)
        let target = try #require(repository.savedTargets.last)
        #expect(target.name == "Cable Vest")
        #expect(target.targetStitches == 22)
        #expect(target.targetRows == 30)
        #expect(target.recommendedNeedle == "4.0 mm")
        #expect(viewModel.targets.map(\.id) == [target.id])
    }

    @Test func saveSwatchAddsSwatchToExistingTarget() async throws {
        let target = Self.makeTarget()
        let repository = GaugeTargetRepositorySpy(targets: [target])
        let viewModel = GaugeMeasureViewModel(repository: repository)
        await viewModel.load()

        viewModel.swatchForm = GaugeSwatchFormData(
            needleSize: " 4.0 mm ",
            needleType: " circular ",
            needleMaterial: " metal ",
            yarnName: " Merino ",
            yarnBrand: " Wool Co ",
            yarnColor: " navy ",
            yarnLot: " A1 ",
            stitchPattern: " stockinette ",
            notes: " first sample "
        )

        let saved = await viewModel.saveSwatch(targetID: target.id)

        #expect(saved == true)
        let savedTarget = try #require(repository.savedTargets.last)
        #expect(savedTarget.swatches.count == 1)
        #expect(savedTarget.swatches[0].needleSize == "4.0 mm")
        #expect(savedTarget.swatches[0].yarnName == "Merino")
        #expect(savedTarget.swatches[0].notes == "first sample")
    }

    @Test func saveManualMeasurementAddsMeasurementToSwatch() async throws {
        let targetID = UUID()
        let swatchID = UUID()
        let swatch = Self.makeSwatch(id: swatchID, targetID: targetID)
        let target = Self.makeTarget(id: targetID, swatches: [swatch])
        let repository = GaugeTargetRepositorySpy(targets: [target])
        let viewModel = GaugeMeasureViewModel(repository: repository)
        await viewModel.load()

        let saved = await viewModel.saveManualMeasurement(
            targetID: targetID,
            swatchID: swatchID,
            washState: .before,
            input: ManualMeasurementInput(
                stitches: "21",
                rows: "28",
                width: "9.5",
                height: "10"
            )
        )

        #expect(saved == true)
        let savedTarget = try #require(repository.savedTargets.last)
        let measurement = try #require(savedTarget.swatches.first?.measurements.first)
        #expect(measurement.method == .manual)
        #expect(measurement.washState == .before)
        #expect(abs(measurement.normalizedStitches - 22.1052) < 0.001)
        #expect(measurement.finalRows == 28)
    }

    @Test func savePhotoMeasurementStoresUserCorrectedCounts() async throws {
        let targetID = UUID()
        let swatchID = UUID()
        let swatch = Self.makeSwatch(id: swatchID, targetID: targetID)
        let target = Self.makeTarget(id: targetID, swatches: [swatch])
        let repository = GaugeTargetRepositorySpy(targets: [target])
        let viewModel = GaugeMeasureViewModel(repository: repository)
        await viewModel.load()

        let saved = await viewModel.savePhotoMeasurement(
            targetID: targetID,
            swatchID: swatchID,
            washState: .after,
            measuredWidth: 8,
            measuredHeight: 9,
            autoResult: GaugeAutoCountResult(stitches: 18, rows: 24, confidence: .medium),
            correctedStitches: 20,
            correctedRows: 27,
            cornerCoordinates: "0,0;1,0;1,1;0,1"
        )

        #expect(saved == true)
        let savedTarget = try #require(repository.savedTargets.last)
        let measurement = try #require(savedTarget.swatches.first?.measurements.first)
        #expect(measurement.method == .photo4pt)
        #expect(measurement.washState == .after)
        #expect(measurement.rawStitches == 20)
        #expect(measurement.rawRows == 27)
        #expect(measurement.autoStitches == 18)
        #expect(measurement.autoRows == 24)
        #expect(measurement.userModified == true)
        #expect(measurement.finalStitches == 25)
        #expect(measurement.finalRows == 30)
        #expect(measurement.cornerCoordinates == "0,0;1,0;1,1;0,1")
    }

    private static func makeTarget(
        id: UUID = UUID(),
        swatches: [GaugeSwatch] = []
    ) -> GaugeTarget {
        let now = Date(timeIntervalSince1970: 100)

        return GaugeTarget(
            id: id,
            name: "Cable Vest",
            targetStitches: 22,
            targetWidth: 10,
            targetRows: 30,
            targetHeight: 10,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced,
            swatches: swatches
        )
    }

    private static func makeSwatch(id: UUID, targetID: UUID) -> GaugeSwatch {
        let now = Date(timeIntervalSince1970: 120)

        return GaugeSwatch(
            id: id,
            gaugeTargetId: targetID,
            isSelected: true,
            knittedAt: now,
            needleSize: "4.0 mm",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }
}

private final class GaugeTargetRepositorySpy: GaugeTargetRepository {
    var targets: [GaugeTarget]
    var savedTargets: [GaugeTarget] = []
    var deletedTargetIDs: [UUID] = []

    init(targets: [GaugeTarget] = []) {
        self.targets = targets
    }

    func fetchGaugeTargets() async throws -> [GaugeTarget] {
        targets
    }

    func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        let saved = GaugeTarget(
            id: target.id,
            ownerId: target.ownerId,
            name: target.name,
            targetStitches: target.targetStitches,
            targetWidth: target.targetWidth,
            targetRows: target.targetRows,
            targetHeight: target.targetHeight,
            isQuickMeasure: target.isQuickMeasure,
            gaugeAfterWash: target.gaugeAfterWash,
            recommendedNeedle: target.recommendedNeedle,
            sourcePatternId: target.sourcePatternId,
            createdAt: target.createdAt,
            updatedAt: Date(timeIntervalSince1970: 200),
            syncStatus: .synced,
            swatches: target.swatches
        )
        savedTargets.append(saved)
        if let index = targets.firstIndex(where: { $0.id == saved.id }) {
            targets[index] = saved
        } else {
            targets.insert(saved, at: 0)
        }
        return saved
    }

    func deleteGaugeTarget(id: UUID) async throws {
        deletedTargetIDs.append(id)
        targets.removeAll { $0.id == id }
    }
}
