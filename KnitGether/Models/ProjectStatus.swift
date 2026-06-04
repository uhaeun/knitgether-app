//
//  ProjectStatus.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum ProjectStatus: String, CaseIterable, Codable, Identifiable {
    case planned = "Planned"
    case wip = "WIP"
    case ufo = "UFO"
    case fo = "FO"

    var id: String {
        rawValue
    }

    var title: String {
        badgeTitle
    }

    var badgeTitle: String {
        switch self {
        case .planned:
            "CO"
        case .wip:
            "WIP"
        case .ufo:
            "UFO"
        case .fo:
            "FO"
        }
    }

    var detailTitle: String {
        switch self {
        case .planned:
            "CO - 시작"
        case .wip:
            "WIP - 진행 중"
        case .ufo:
            "UFO - 잠시 멈춤"
        case .fo:
            "FO - 완성"
        }
    }
}
