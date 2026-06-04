//
//  SkillRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol SkillRepository {
    func fetchSkills() async throws -> [Skill]
    func fetchSkillAnimations() async throws -> [SkillAnimation]
}
