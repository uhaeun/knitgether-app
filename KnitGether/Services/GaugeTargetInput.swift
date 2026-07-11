import Foundation

struct GaugeTargetInput {
    struct Validated {
        let name: String
        let stitches: Double
        let rows: Double
        let width: Double
        let height: Double

        var stitchesPer10cm: Double {
            stitches / width * 10
        }

        var rowsPer10cm: Double {
            rows > 0 ? rows / height * 10 : 0
        }
    }

    let name: String
    let width: String
    let height: String
    let stitches: String
    let rows: String

    var validated: Validated? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmedName.isEmpty,
            let widthValue = Self.decimalValue(from: width),
            widthValue > 0,
            let heightValue = Self.decimalValue(from: height),
            heightValue > 0,
            let stitchesValue = Self.decimalValue(from: stitches),
            stitchesValue > 0
        else {
            return nil
        }

        let rowsValue = Self.decimalValue(from: rows) ?? 0

        guard rowsValue >= 0 else {
            return nil
        }

        return Validated(
            name: trimmedName,
            stitches: stitchesValue,
            rows: rowsValue,
            width: widthValue,
            height: heightValue
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
