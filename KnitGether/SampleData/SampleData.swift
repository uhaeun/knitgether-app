//
//  SampleData.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum SampleData {
    static let ownerId = "local-user"

    private static let cardiganProjectId = UUID()
    private static let beanieProjectId = UUID()
    private static let scarfProjectId = UUID()
    private static let cableSkillId = UUID()
    private static let increasesSkillId = UUID()
    private static let cableAnimationId = UUID()

    static let profile = UserProfile(
        id: ownerId,
        ownerId: ownerId,
        displayName: "Local Knitter",
        preferredUnits: "Metric",
        createdAt: makeDate(year: 2026, month: 6, day: 1),
        updatedAt: makeDate(year: 2026, month: 6, day: 1),
        deletedAt: nil,
        syncStatus: .localOnly
    )

    static let patternDocuments: [PatternDocument] = [
        PatternDocument(
            ownerId: ownerId,
            title: "Cozy Cardigan",
            designer: "KnitGether Studio",
            fileName: "cozy-cardigan.pdf",
            localFilePath: nil,
            pageCount: 8,
            notes: "Library original. Project imports should create snapshots.",
            createdAt: makeDate(year: 2026, month: 4, day: 2),
            updatedAt: makeDate(year: 2026, month: 4, day: 2)
        ),
        PatternDocument(
            ownerId: ownerId,
            title: "Classic Cable Scarf",
            designer: "Sample Designer",
            fileName: "classic-cable-scarf.pdf",
            localFilePath: nil,
            pageCount: 4,
            notes: "Good beginner cable reference.",
            createdAt: makeDate(year: 2026, month: 3, day: 1),
            updatedAt: makeDate(year: 2026, month: 3, day: 1)
        )
    ]

    static let yarns: [Yarn] = [
        Yarn(
            id: UUID(),
            ownerId: ownerId,
            name: "Soft Merino DK",
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: 5,
            notes: "Reserved for beanie and swatches.",
            createdAt: makeDate(year: 2026, month: 5, day: 18),
            updatedAt: makeDate(year: 2026, month: 5, day: 18),
            deletedAt: nil,
            syncStatus: .localOnly
        )
    ]

    static let needles: [Needle] = [
        Needle(
            id: UUID(),
            ownerId: ownerId,
            name: "Wood Circular Needle",
            needleType: "Circular",
            size: "5.0 mm",
            length: "80 cm",
            notes: "Used for cardigan body.",
            createdAt: makeDate(year: 2026, month: 4, day: 1),
            updatedAt: makeDate(year: 2026, month: 4, day: 1),
            deletedAt: nil,
            syncStatus: .localOnly
        )
    ]

    static let skillAnimations: [SkillAnimation] = [
        SkillAnimation(
            id: cableAnimationId,
            ownerId: ownerId,
            skillId: cableSkillId,
            title: "Cable Cross Demo",
            localAssetName: nil,
            durationSeconds: 24,
            createdAt: makeDate(year: 2026, month: 3, day: 1),
            updatedAt: makeDate(year: 2026, month: 3, day: 1),
            deletedAt: nil,
            syncStatus: .localOnly
        )
    ]

    static let skills: [Skill] = [
        Skill(
            id: cableSkillId,
            ownerId: ownerId,
            title: "Cable Cross",
            category: "Texture",
            summary: "Move stitches out of order to create cable twists.",
            steps: ["Slip stitches to cable needle.", "Hold front or back.", "Knit next stitches.", "Knit held stitches."],
            animationIds: [cableAnimationId],
            createdAt: makeDate(year: 2026, month: 3, day: 1),
            updatedAt: makeDate(year: 2026, month: 3, day: 1),
            deletedAt: nil,
            syncStatus: .localOnly
        ),
        Skill(
            id: increasesSkillId,
            ownerId: ownerId,
            title: "Make One Increase",
            category: "Shaping",
            summary: "Add a stitch between existing stitches with a lifted bar.",
            steps: ["Lift the bar between stitches.", "Place it on the left needle.", "Knit through the back loop."],
            animationIds: [],
            createdAt: makeDate(year: 2026, month: 4, day: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 10),
            deletedAt: nil,
            syncStatus: .localOnly
        )
    ]

    static let projects: [KnittingProject] = {
        let cardiganPattern = patternDocuments[0]
        let scarfPattern = patternDocuments[1]

        let cardiganCopy = ProjectPatternCopy(
            ownerId: ownerId,
            projectId: cardiganProjectId,
            sourcePatternDocumentId: cardiganPattern.id,
            titleSnapshot: cardiganPattern.title,
            designerSnapshot: cardiganPattern.designer,
            fileNameSnapshot: cardiganPattern.fileName,
            localCopyPath: nil,
            pageCountSnapshot: cardiganPattern.pageCount,
            copiedAt: makeDate(year: 2026, month: 4, day: 12),
            createdAt: makeDate(year: 2026, month: 4, day: 12),
            updatedAt: makeDate(year: 2026, month: 4, day: 12)
        )

        let scarfCopy = ProjectPatternCopy(
            ownerId: ownerId,
            projectId: scarfProjectId,
            sourcePatternDocumentId: scarfPattern.id,
            titleSnapshot: scarfPattern.title,
            designerSnapshot: scarfPattern.designer,
            fileNameSnapshot: scarfPattern.fileName,
            localCopyPath: nil,
            pageCountSnapshot: scarfPattern.pageCount,
            copiedAt: makeDate(year: 2026, month: 3, day: 7),
            createdAt: makeDate(year: 2026, month: 3, day: 7),
            updatedAt: makeDate(year: 2026, month: 3, day: 7)
        )

        return [
            KnittingProject(
                id: cardiganProjectId,
                ownerId: ownerId,
                name: "Weekend Cardigan",
                status: .wip,
                isFavorite: true,
                memo: "Working on the second sleeve. Check decrease notes before the next session.",
                startDate: makeDate(year: 2026, month: 4, day: 12),
                lastWorkedAt: makeDate(year: 2026, month: 6, day: 1),
                patternCopy: cardiganCopy,
                rowCounter: RowCounter(
                    ownerId: ownerId,
                    projectId: cardiganProjectId,
                    currentRow: 42,
                    targetRow: 88,
                    createdAt: makeDate(year: 2026, month: 4, day: 12),
                    updatedAt: makeDate(year: 2026, month: 6, day: 1)
                ),
                workSessions: [
                    WorkSession(
                        ownerId: ownerId,
                        projectId: cardiganProjectId,
                        startedAt: makeDateTime(year: 2026, month: 6, day: 1, hour: 19, minute: 0),
                        endedAt: makeDateTime(year: 2026, month: 6, day: 1, hour: 20, minute: 25),
                        memo: "Second sleeve progress.",
                        createdAt: makeDate(year: 2026, month: 6, day: 1),
                        updatedAt: makeDate(year: 2026, month: 6, day: 1)
                    ),
                    WorkSession(
                        ownerId: ownerId,
                        projectId: cardiganProjectId,
                        startedAt: makeDateTime(year: 2026, month: 5, day: 30, hour: 18, minute: 30),
                        endedAt: makeDateTime(year: 2026, month: 5, day: 30, hour: 19, minute: 20),
                        memo: "Sleeve ribbing.",
                        createdAt: makeDate(year: 2026, month: 5, day: 30),
                        updatedAt: makeDate(year: 2026, month: 5, day: 30)
                    )
                ],
                relatedSkillIds: [increasesSkillId],
                createdAt: makeDate(year: 2026, month: 4, day: 12),
                updatedAt: makeDate(year: 2026, month: 6, day: 1)
            ),
            KnittingProject(
                id: beanieProjectId,
                ownerId: ownerId,
                name: "Soft Ribbed Beanie",
                status: .planned,
                isFavorite: false,
                memo: "Use gray merino yarn and swatch before casting on.",
                startDate: makeDate(year: 2026, month: 5, day: 20),
                lastWorkedAt: nil,
                patternCopy: nil,
                rowCounter: RowCounter(
                    ownerId: ownerId,
                    projectId: beanieProjectId,
                    currentRow: 0,
                    targetRow: nil,
                    createdAt: makeDate(year: 2026, month: 5, day: 20),
                    updatedAt: makeDate(year: 2026, month: 5, day: 20)
                ),
                workSessions: [],
                relatedSkillIds: [],
                createdAt: makeDate(year: 2026, month: 5, day: 20),
                updatedAt: makeDate(year: 2026, month: 5, day: 20)
            ),
            KnittingProject(
                id: scarfProjectId,
                ownerId: ownerId,
                name: "Blue Cable Scarf",
                status: .ufo,
                isFavorite: true,
                memo: "Paused after repeat 6. Resume with cable needle size 5 mm.",
                startDate: makeDate(year: 2026, month: 3, day: 7),
                lastWorkedAt: makeDate(year: 2026, month: 5, day: 9),
                patternCopy: scarfCopy,
                rowCounter: RowCounter(
                    ownerId: ownerId,
                    projectId: scarfProjectId,
                    currentRow: 88,
                    targetRow: 120,
                    createdAt: makeDate(year: 2026, month: 3, day: 7),
                    updatedAt: makeDate(year: 2026, month: 5, day: 9)
                ),
                workSessions: [
                    WorkSession(
                        ownerId: ownerId,
                        projectId: scarfProjectId,
                        startedAt: makeDateTime(year: 2026, month: 5, day: 9, hour: 16, minute: 0),
                        endedAt: makeDateTime(year: 2026, month: 5, day: 9, hour: 17, minute: 10),
                        memo: "Finished repeat 6.",
                        createdAt: makeDate(year: 2026, month: 5, day: 9),
                        updatedAt: makeDate(year: 2026, month: 5, day: 9)
                    )
                ],
                relatedSkillIds: [cableSkillId],
                createdAt: makeDate(year: 2026, month: 3, day: 7),
                updatedAt: makeDate(year: 2026, month: 5, day: 9)
            )
        ]
    }()

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private static func makeDateTime(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
    }
}
