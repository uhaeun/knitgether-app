//
//  ProjectStatus.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum ProjectStatus: String, CaseIterable, Identifiable {
    case planning = "Planning"
    case inProgress = "In Progress"
    case paused = "Paused"
    case finished = "Finished"

    var id: String {
        rawValue
    }
}
