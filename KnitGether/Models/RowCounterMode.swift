//
//  RowCounterMode.swift
//  KnitGether
//
//  Created by Codex on 7/6/26.
//

import Foundation

enum RowCounterMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case simple
    case rowGuide

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .simple:
            return "간편 모드"
        case .rowGuide:
            return "행안내 모드"
        }
    }
}
