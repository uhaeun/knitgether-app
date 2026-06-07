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

    private let userDefaults: UserDefaults
    private var isRestoringInputs = false

    init(userDefaults: UserDefaults = .standard) {
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
            memo
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
        isRestoringInputs = false
        persistInputs()
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
    }
}
