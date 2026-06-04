//
//  SyncStatus.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

enum SyncStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case localOnly = "Local Only"
    case pendingUpload = "Pending Upload"
    case synced = "Synced"
    case pendingDelete = "Pending Delete"
    case conflict = "Conflict"

    var id: String {
        rawValue
    }
}
