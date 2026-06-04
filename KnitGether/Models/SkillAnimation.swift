//
//  SkillAnimation.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct SkillAnimation: Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let skillId: UUID?
    let title: String
    let localAssetName: String?
    let durationSeconds: Int?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
}
