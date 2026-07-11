//
//  SkillRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol SkillRepository {
    func fetchSkills() async throws -> [Skill]
    func fetchSkill(id: UUID) async throws -> Skill?
    func saveSkill(_ skill: Skill) async throws
    func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill
    func deleteSkill(id: UUID) async throws
    func fetchSkillAnimations() async throws -> [SkillAnimation]
}

extension SkillRepository {
    func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill {
        guard let skill = try await fetchSkill(id: skillId) else {
            throw APIError.unsupportedOperation("Skill not found.")
        }

        let updatedSkill = skill.updatingUserLevel(
            level,
            updatedAt: Date(),
            syncStatus: skill.syncStatus == .synced ? .pendingUpload : skill.syncStatus
        )
        try await saveSkill(updatedSkill)
        return updatedSkill
    }
}
