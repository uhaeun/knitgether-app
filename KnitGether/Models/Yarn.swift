//
//  Yarn.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct Yarn: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let brand: String?
    let colorway: String?
    let weight: String?
    let quantity: Int
    let notes: String
    var photoContentType: String? = nil
    var photoByteSize: Int? = nil
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
}
