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
