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

    var displayTitle: String {
        switch self {
        case .localOnly:
            return "이 기기에만 있음"
        case .pendingUpload:
            return "서버 저장 대기"
        case .synced:
            return "서버 저장됨"
        case .pendingDelete:
            return "삭제 대기"
        case .conflict:
            return "확인 필요"
        }
    }

    var badgeSystemImage: String {
        switch self {
        case .localOnly:
            return "iphone"
        case .pendingUpload:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud.fill"
        case .pendingDelete:
            return "trash"
        case .conflict:
            return "exclamationmark.triangle.fill"
        }
    }

    var detailText: String {
        switch self {
        case .localOnly:
            return "아직 이 기기에만 저장되어 있어요."
        case .pendingUpload:
            return "서버 저장을 기다리고 있어요."
        case .synced:
            return "현재 계정에 저장되어 있어요."
        case .pendingDelete:
            return "서버 삭제 반영을 기다리고 있어요."
        case .conflict:
            return "서버 저장 상태 확인이 필요해요."
        }
    }

    var needsSync: Bool {
        self != .synced
    }

    var needsUpload: Bool {
        self == .localOnly || self == .pendingUpload || self == .pendingDelete
    }

    var needsUserAttention: Bool {
        self == .conflict
    }
}
