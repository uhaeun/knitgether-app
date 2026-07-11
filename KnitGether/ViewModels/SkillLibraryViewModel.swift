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
    @Published private(set) var skillAnimations: [SkillAnimation] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRetryingSync = false
    @Published var searchText = ""

    private let skillRepository: any SkillRepository

    init(skillRepository: any SkillRepository) {
        self.skillRepository = skillRepository
    }

    var filteredSkills: [Skill] {
        Self.filteredSkills(skills, matching: searchText)
    }

    var animationSkills: [Skill] {
        skills.filter { skill in
            skill.animationName != nil || skill.animationType != nil || !skill.animationIds.isEmpty
                || !animations(for: skill).isEmpty
        }
    }

    var hasSkillsNeedingSync: Bool {
        skills.contains { $0.syncStatus.needsSync }
    }

    func loadSkills() async {
        do {
            skills = try await skillRepository.fetchSkills()
            skillAnimations = try await skillRepository.fetchSkillAnimations()
            errorMessage = nil
        } catch {
            errorMessage = "스킬을 불러오지 못했어요."
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadSkills()
        isRetryingSync = false
    }

    func animations(for skill: Skill) -> [SkillAnimation] {
        skillAnimations.filter { animation in
            animation.skillId == skill.id || skill.animationIds.contains(animation.id)
        }
    }

    func addSkill(from formData: SkillFormData) async -> Bool {
        await saveSkill(from: formData, existingSkill: nil)
    }

    func updateSkill(_ skill: Skill, from formData: SkillFormData) async -> Bool {
        guard !skill.isSystem else {
            errorMessage = "기본 제공 스킬은 수정할 수 없어요."
            return false
        }

        return await saveSkill(from: formData, existingSkill: skill)
    }

    @discardableResult
    func deleteSkill(_ skill: Skill) async -> Bool {
        guard !skill.isSystem else {
            errorMessage = "기본 제공 스킬은 삭제할 수 없어요."
            return false
        }

        do {
            try await skillRepository.deleteSkill(id: skill.id)
            await loadSkills()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "스킬을 삭제하지 못했어요."
            return false
        }
    }

    private func saveSkill(from formData: SkillFormData, existingSkill: Skill?) async -> Bool {
        guard formData.canSave else {
            errorMessage = "스킬 이름, 약어, 설명을 입력해 주세요."
            return false
        }

        let now = Date()
        let skill = Skill(
            id: existingSkill?.id ?? UUID(),
            ownerId: existingSkill?.ownerId ?? SampleData.ownerId,
            name: formData.trimmedName,
            abbreviation: formData.trimmedAbbreviation,
            description: formData.trimmedDescription,
            category: formData.trimmedCategory,
            difficulty: formData.trimmedDifficulty,
            animationName: formData.trimmedAnimationName,
            animationType: formData.trimmedAnimationType,
            isSystem: existingSkill?.isSystem ?? false,
            userLevel: existingSkill?.userLevel,
            createdAt: existingSkill?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingSkill?.deletedAt,
            syncStatus: existingSkill?.syncStatus ?? .localOnly,
            steps: formData.steps,
            animationIds: formData.animationIds
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
