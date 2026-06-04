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
    func deleteSkill(id: UUID) async throws
    func fetchSkillAnimations() async throws -> [SkillAnimation]
}
