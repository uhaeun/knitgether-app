//
//  Needle.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct Needle: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let needleType: String
    let size: String
    let length: String?
    let notes: String
    var photoContentType: String? = nil
    var photoByteSize: Int? = nil
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus
}
