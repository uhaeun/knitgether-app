//
//  RemoteSkillRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

final class RemoteSkillRepository: SkillRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchSkills() async throws -> [Skill] {
        try await apiClient.get("skills")
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        do {
            return try await apiClient.get("skills/\(id.uuidString.lowercased())")
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveSkill(_ skill: Skill) async throws {
        let body = SaveSkillRequest(skill: skill)

        if skill.syncStatus == .synced {
            let _: Skill = try await apiClient.send(
                "skills/\(skill.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: Skill = try await apiClient.send(
                "skills",
                method: "POST",
                body: body
            )
        }
    }

    func saveSkillLevel(skillId: UUID, level: String) async throws -> Skill {
        try await apiClient.send(
            "skills/\(skillId.uuidString.lowercased())/level",
            method: "PATCH",
            body: SaveSkillLevelRequest(level: level)
        )
    }

    func deleteSkill(id: UUID) async throws {
        try await apiClient.delete("skills/\(id.uuidString.lowercased())")
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        try await apiClient.get("skill-animations")
    }
}

private struct SaveSkillLevelRequest: Encodable {
    let level: String
}

private struct SaveSkillRequest: Encodable {
    let id: String
    let name: String
    let abbreviation: String
    let description: String
    let category: String?
    let difficulty: String?
    let animationName: String?
    let animationType: String?
    let steps: [String]
    let animationIds: [String]

    init(skill: Skill) {
        id = skill.id.uuidString.lowercased()
        name = skill.name
        abbreviation = skill.abbreviation
        description = skill.description
        category = skill.category
        difficulty = skill.difficulty
        animationName = skill.animationName
        animationType = skill.animationType
        steps = skill.steps
        animationIds = skill.animationIds.map { $0.uuidString.lowercased() }
    }
}
