//
//  ProjectFormData.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct ProjectFormData {
    var name: String
    var status: ProjectStatus
    var startDate: Date
    var memo: String
    var isFavorite: Bool
    var patternName: String

    init(
        name: String = "",
        status: ProjectStatus = .planned,
        startDate: Date = Date(),
        memo: String = "",
        isFavorite: Bool = false,
        patternName: String = ""
    ) {
        self.name = name
        self.status = status
        self.startDate = startDate
        self.memo = memo
        self.isFavorite = isFavorite
        self.patternName = patternName
    }

    init(project: KnittingProject) {
        name = project.name
        status = project.status
        startDate = project.startDate
        memo = project.memo
        isFavorite = project.isFavorite
        patternName = project.patternCopy?.titleSnapshot ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMemo: String {
        memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedPatternName: String {
        patternName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }
}
