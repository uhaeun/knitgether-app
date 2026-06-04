//
//  ProjectWorkspaceSheetPosition.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

enum ProjectWorkspaceSheetPosition: String, Codable, CaseIterable, Identifiable, Hashable {
    case collapsed
    case medium
    case expanded

    var id: String {
        rawValue
    }

    init(displayMode: ProjectWorkspaceDisplayMode?) {
        switch displayMode {
        case .patternOnly:
            self = .collapsed
        case .patternAndCounter:
            self = .medium
        case .counterOnly:
            self = .expanded
        case nil:
            self = .medium
        }
    }
}
