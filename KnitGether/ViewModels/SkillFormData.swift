//
//  SkillFormData.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct SkillFormData {
    var name = ""
    var abbreviation = ""
    var description = ""
    var category = ""
    var difficulty = ""

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAbbreviation: String {
        abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCategory: String? {
        let value = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var trimmedDifficulty: String? {
        let value = difficulty.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedAbbreviation.isEmpty && !trimmedDescription.isEmpty
    }
}
