//
//  UserProfile.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: String
    var ownerId: String?
    let displayName: String
    let preferredUnits: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
}
