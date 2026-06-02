//
//  SampleKnittingData.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum SampleKnittingData {
    static let projects: [KnittingProject] = [
        KnittingProject(
            name: "Weekend Cardigan",
            status: .inProgress,
            isFavorite: true,
            patternName: "Cozy Cardigan",
            memo: "Working on the second sleeve. Need to check the decrease notes before the next session.",
            startDate: makeDate(year: 2026, month: 4, day: 12),
            lastWorkedDate: makeDate(year: 2026, month: 6, day: 1),
            currentRow: 42
        ),
        KnittingProject(
            name: "Soft Ribbed Beanie",
            status: .planning,
            isFavorite: false,
            patternName: nil,
            memo: "Use the gray merino yarn and swatch before casting on.",
            startDate: makeDate(year: 2026, month: 5, day: 20),
            lastWorkedDate: makeDate(year: 2026, month: 5, day: 20),
            currentRow: 0
        ),
        KnittingProject(
            name: "Blue Cable Scarf",
            status: .paused,
            isFavorite: true,
            patternName: "Classic Cable Scarf",
            memo: "Paused after repeat 6. Resume with cable needle size 5 mm.",
            startDate: makeDate(year: 2026, month: 3, day: 7),
            lastWorkedDate: makeDate(year: 2026, month: 5, day: 9),
            currentRow: 88
        ),
        KnittingProject(
            name: "Tiny Gift Socks",
            status: .finished,
            isFavorite: false,
            patternName: "Simple Sock Recipe",
            memo: "Finished pair for gifting. Blocked and ready.",
            startDate: makeDate(year: 2026, month: 2, day: 18),
            lastWorkedDate: makeDate(year: 2026, month: 4, day: 3),
            currentRow: 64
        )
    ]

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
