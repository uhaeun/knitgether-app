//
//  YarnFormData.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import Foundation

struct YarnFormData {
    var name = ""
    var brand = ""
    var colorName = ""
    var colorCode = ""
    var weight = ""
    var lengthMeters = ""
    var fiberContent = ""
    var gaugeMemo = ""
    var quantity = ""
    var memo = ""

    init() {
    }

    init(yarn: Yarn) {
        name = yarn.name
        brand = yarn.brand ?? ""
        colorName = yarn.colorName ?? ""
        colorCode = yarn.colorCode ?? ""
        weight = yarn.weight ?? ""
        lengthMeters = yarn.lengthMeters.map { Self.formattedNumber($0) } ?? ""
        fiberContent = yarn.fiberContent ?? ""
        gaugeMemo = yarn.gaugeMemo ?? ""
        quantity = yarn.quantity.map(String.init) ?? ""
        memo = yarn.memo ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }

    var lengthMetersValue: Double? {
        let value = lengthMeters
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !value.isEmpty else {
            return nil
        }

        return Double(value)
    }

    var quantityValue: Int? {
        let value = quantity.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            return nil
        }

        return Int(value)
    }

    var trimmedBrand: String? {
        optionalString(brand)
    }

    var trimmedColorName: String? {
        optionalString(colorName)
    }

    var trimmedColorCode: String? {
        optionalString(colorCode)
    }

    var trimmedWeight: String? {
        optionalString(weight)
    }

    var trimmedFiberContent: String? {
        optionalString(fiberContent)
    }

    var trimmedGaugeMemo: String? {
        optionalString(gaugeMemo)
    }

    var trimmedMemo: String? {
        optionalString(memo)
    }

    private func optionalString(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private static func formattedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
