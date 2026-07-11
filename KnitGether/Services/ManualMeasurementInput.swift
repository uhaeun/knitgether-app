import Foundation

struct ManualMeasurementInput {
    struct Normalized {
        let stitchesPer10cm: Double
        let rowsPer10cm: Double
    }

    let stitches: String
    let rows: String
    let width: String
    let height: String

    var normalized: Normalized? {
        guard
            let stitchesValue = Self.decimalValue(from: stitches),
            stitchesValue > 0,
            let widthValue = Self.decimalValue(from: width),
            widthValue > 0,
            let heightValue = Self.decimalValue(from: height),
            heightValue > 0
        else {
            return nil
        }

        let rowsValue = Self.decimalValue(from: rows) ?? 0

        guard rowsValue >= 0 else {
            return nil
        }

        return Normalized(
            stitchesPer10cm: stitchesValue / widthValue * 10,
            rowsPer10cm: rowsValue > 0 ? rowsValue / heightValue * 10 : 0
        )
    }

    private static func decimalValue(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else {
            return nil
        }

        return Double(normalized)
    }
}
