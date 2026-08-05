//
//  ProjectWorkspaceDisplayMode.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

enum ProjectWorkspaceDisplayMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case patternOnly
    case patternAndCounter
    case counterOnly

    var id: String {
        rawValue
    }

    // patternOnly는 저장 호환용으로만 유지하고 선택지에서는 제외한다
    static let selectableCases: [ProjectWorkspaceDisplayMode] = [.patternAndCounter, .counterOnly]

    var title: String {
        switch self {
        case .patternOnly:
            return "도안만"
        case .patternAndCounter:
            return "도안+카운터"
        case .counterOnly:
            return "카운터만"
        }
    }
}
