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
    let title: String
    let category: String
    let summary: String
    let steps: [String]
    let animationIds: [UUID]
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
}
