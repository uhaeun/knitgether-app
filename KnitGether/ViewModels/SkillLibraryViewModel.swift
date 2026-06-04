//
//  SkillLibraryViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

@MainActor
final class SkillLibraryViewModel: ObservableObject {
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var animations: [SkillAnimation] = []
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private let skillRepository: any SkillRepository

    init(skillRepository: any SkillRepository) {
        self.skillRepository = skillRepository
    }

    var filteredSkills: [Skill] {
        Self.filteredSkills(skills, matching: searchText)
    }

    var animationSkills: [Skill] {
        let skillsWithAnimation = skills.filter { skill in
            skill.animationName != nil || skill.animationType != nil || !skill.animationIds.isEmpty
        }

        return skillsWithAnimation.isEmpty ? skills : skillsWithAnimation
    }

    func loadSkills() async {
        do {
            skills = try await skillRepository.fetchSkills()
            animations = try await skillRepository.fetchSkillAnimations()
            errorMessage = nil
        } catch {
            errorMessage = "스킬을 불러오지 못했어요."
        }
    }

    func addSkill(from formData: SkillFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "스킬 이름, 약어, 설명을 입력해 주세요."
            return false
        }

        let now = Date()
        let skill = Skill(
            ownerId: SampleData.ownerId,
            name: formData.trimmedName,
            abbreviation: formData.trimmedAbbreviation,
            description: formData.trimmedDescription,
            category: formData.trimmedCategory,
            difficulty: formData.trimmedDifficulty,
            animationName: nil,
            animationType: nil,
            createdAt: now,
            updatedAt: now
        )

        do {
            try await skillRepository.saveSkill(skill)
            await loadSkills()
            return true
        } catch {
            errorMessage = "스킬을 저장하지 못했어요."
            return false
        }
    }

    static func filteredSkills(_ skills: [Skill], matching searchText: String) -> [Skill] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return skills
        }

        return skills.filter { skill in
            skill.name.localizedCaseInsensitiveContains(query)
                || skill.abbreviation.localizedCaseInsensitiveContains(query)
                || skill.description.localizedCaseInsensitiveContains(query)
                || skill.category?.localizedCaseInsensitiveContains(query) == true
        }
    }
}
