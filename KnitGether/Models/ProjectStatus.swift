//
//  ProjectStatus.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum ProjectStatus: String, CaseIterable, Identifiable {
    case planned = "Planned"
    case wip = "WIP"
    case ufo = "UFO"
    case fo = "FO"

    var id: String {
        rawValue
    }

    var title: String {
        rawValue
    }
}
