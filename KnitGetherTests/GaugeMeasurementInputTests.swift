import Testing
import UIKit
@testable import KnitGether

struct GaugeMeasurementInputTests {
    @Test func manualMeasurementInputNormalizesStitchesAndRowsPer10cm() throws {
        let input = ManualMeasurementInput(
            stitches: "22",
            rows: "30",
            width: "10",
            height: "12"
        )

        let normalized = try #require(input.normalized)

        #expect(normalized.stitchesPer10cm == 22)
        #expect(normalized.rowsPer10cm == 25)
    }

    @Test func manualMeasurementInputAcceptsCommaDecimalsAndOptionalRows() throws {
        let input = ManualMeasurementInput(
            stitches: "18,5",
            rows: "",
            width: "8,5",
            height: "10"
        )

        let normalized = try #require(input.normalized)

        #expect(abs(normalized.stitchesPer10cm - 21.7647) < 0.001)
        #expect(normalized.rowsPer10cm == 0)
    }

    @Test func gaugeTargetInputRequiresNamedPositiveTarget() throws {
        let input = GaugeTargetInput(
            name: "  Cable Vest  ",
            width: "10",
            height: "10",
            stitches: "22",
            rows: "30"
        )

        let validated = try #require(input.validated)

        #expect(validated.name == "Cable Vest")
        #expect(validated.stitchesPer10cm == 22)
        #expect(validated.rowsPer10cm == 30)
    }

    @Test func photoMeasurementSourcesFallbackToPhotoLibraryInTests() {
        #expect(PhotoMeasurementSource.photoLibrary.displayName == "사진 앨범에서 선택")
        #expect(PhotoMeasurementSource.photoLibrary.icon == "photo.on.rectangle")
        #expect(PhotoMeasurementSource.availableSources().contains(.photoLibrary))
    }

    @Test func autoCounterRejectsSelectionsThatAreNotFourPoints() {
        let image = UIImage()

        let result = GaugeAutoCounter().estimateCounts(
            in: image,
            cornerPoints: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.9, y: 0.1)]
        )

        #expect(result == nil)
    }
}
