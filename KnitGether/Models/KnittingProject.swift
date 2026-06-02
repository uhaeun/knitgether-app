//
//  KnittingProject.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

struct KnittingProject: Identifiable, Hashable {
    let id: UUID
    let name: String
    let status: ProjectStatus
    let isFavorite: Bool
    let patternName: String?
    let memo: String
    let startDate: Date
    let lastWorkedDate: Date
    let currentRow: Int

    init(
        id: UUID = UUID(),
        name: String,
        status: ProjectStatus,
        isFavorite: Bool,
        patternName: String?,
        memo: String,
        startDate: Date,
        lastWorkedDate: Date,
        currentRow: Int
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.isFavorite = isFavorite
        self.patternName = patternName
        self.memo = memo
        self.startDate = startDate
        self.lastWorkedDate = lastWorkedDate
        self.currentRow = currentRow
    }
}
