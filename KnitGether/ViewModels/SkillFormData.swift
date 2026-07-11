//
//  SkillFormData.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

nonisolated struct SkillFormData {
    var name = ""
    var abbreviation = ""
    var description = ""
    var category = ""
    var difficulty = ""
    var stepsText = ""
    var animationName = ""
    var animationType = ""
    var animationIds: [UUID] = []

    init() {
    }

    init(skill: Skill) {
        name = skill.name
        abbreviation = skill.abbreviation
        description = skill.description
        category = skill.category ?? ""
        difficulty = skill.difficulty ?? ""
        stepsText = skill.steps.joined(separator: "\n")
        animationName = skill.animationName ?? ""
        animationType = skill.animationType ?? ""
        animationIds = skill.animationIds
    }

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

    var trimmedAnimationName: String? {
        let value = animationName.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var trimmedAnimationType: String? {
        let value = animationType.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var steps: [String] {
        stepsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedAbbreviation.isEmpty && !trimmedDescription.isEmpty
    }
}
