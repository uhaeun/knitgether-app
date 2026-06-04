//
//  Skill.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct Skill: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let abbreviation: String
    let description: String
    let category: String?
    let difficulty: String?
    let animationName: String?
    let animationType: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    let steps: [String]
    let animationIds: [UUID]

    var title: String {
        name
    }

    var summary: String {
        description
    }

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        name: String,
        abbreviation: String,
        description: String,
        category: String? = nil,
        difficulty: String? = nil,
        animationName: String? = nil,
        animationType: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly,
        steps: [String] = [],
        animationIds: [UUID] = []
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.abbreviation = abbreviation
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.animationName = animationName
        self.animationType = animationType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
        self.steps = steps
        self.animationIds = animationIds
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case name
        case abbreviation
        case description
        case category
        case difficulty
        case animationName
        case animationType
        case createdAt
        case updatedAt
        case deletedAt
        case syncStatus
        case title
        case summary
        case steps
        case animationIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? ""
        abbreviation = try container.decodeIfPresent(String.self, forKey: .abbreviation) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
            ?? container.decodeIfPresent(String.self, forKey: .summary)
            ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        animationName = try container.decodeIfPresent(String.self, forKey: .animationName)
        animationType = try container.decodeIfPresent(String.self, forKey: .animationType)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .localOnly
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        animationIds = try container.decodeIfPresent([UUID].self, forKey: .animationIds) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encode(abbreviation, forKey: .abbreviation)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(animationName, forKey: .animationName)
        try container.encodeIfPresent(animationType, forKey: .animationType)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(syncStatus, forKey: .syncStatus)
        try container.encode(steps, forKey: .steps)
        try container.encode(animationIds, forKey: .animationIds)
    }
}
