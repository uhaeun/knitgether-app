//
//  SampleData.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation

enum SampleData {
    static let ownerId = "local-user"

    struct BundledPatternResource {
        let title: String
        let fileName: String
        let notes: String
        let createdAt: Date
        let updatedAt: Date
    }

    private static let cardiganProjectId = UUID()
    private static let beanieProjectId = UUID()
    private static let scarfProjectId = UUID()
    private static let knitSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656601") ?? UUID()
    private static let purlSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656602") ?? UUID()
    private static let castOnSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656603") ?? UUID()
    private static let bindOffSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656604") ?? UUID()
    private static let yarnOverSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656605") ?? UUID()
    private static let slipSkillId = UUID(uuidString: "0A6C3D28-F710-48D6-9810-8BAA8F656606") ?? UUID()
    private static let knitAnimationId = UUID(uuidString: "8D032BB0-7085-47D7-A4B2-326ACEDDA001") ?? UUID()

    static let bundledPatternResources: [BundledPatternResource] = [
        BundledPatternResource(
            title: "sample1",
            fileName: "sample1.pdf",
            notes: "앱에 포함된 샘플 도안입니다.",
            createdAt: makeDate(year: 2026, month: 6, day: 4),
            updatedAt: makeDate(year: 2026, month: 6, day: 4)
        ),
        BundledPatternResource(
            title: "sample2",
            fileName: "sample2.pdf",
            notes: "앱에 포함된 샘플 도안입니다.",
            createdAt: makeDate(year: 2026, month: 6, day: 4),
            updatedAt: makeDate(year: 2026, month: 6, day: 4)
        ),
        BundledPatternResource(
            title: "sample3",
            fileName: "sample3.pdf",
            notes: "앱에 포함된 샘플 도안입니다.",
            createdAt: makeDate(year: 2026, month: 6, day: 4),
            updatedAt: makeDate(year: 2026, month: 6, day: 4)
        ),
        BundledPatternResource(
            title: "sample4",
            fileName: "sample4.pdf",
            notes: "앱에 포함된 샘플 도안입니다.",
            createdAt: makeDate(year: 2026, month: 6, day: 4),
            updatedAt: makeDate(year: 2026, month: 6, day: 4)
        )
    ]

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
            notes: "Library 원본 도안입니다. 프로젝트로 가져오면 사본이 만들어집니다.",
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
            notes: "케이블 연습용 샘플 도안입니다.",
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
            id: knitAnimationId,
            ownerId: ownerId,
            skillId: knitSkillId,
            title: "겉뜨기 기본 동작",
            localAssetName: nil,
            durationSeconds: 18,
            createdAt: makeDate(year: 2026, month: 3, day: 1),
            updatedAt: makeDate(year: 2026, month: 3, day: 1),
            deletedAt: nil,
            syncStatus: .localOnly
        )
    ]

    static let skills: [Skill] = [
        Skill(
            id: knitSkillId,
            ownerId: ownerId,
            name: "겉뜨기",
            abbreviation: "K",
            description: "오른쪽 바늘을 코의 앞쪽에 넣고 실을 걸어 빼내는 가장 기본적인 뜨개 방법입니다.",
            category: "기본",
            difficulty: "초급",
            animationName: "겉뜨기 기본 동작",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 3, day: 1),
            updatedAt: makeDate(year: 2026, month: 3, day: 1),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["오른쪽 바늘을 앞에서 뒤로 넣습니다.", "실을 걸어 새 코를 빼냅니다.", "왼쪽 바늘의 기존 코를 빼냅니다."],
            animationIds: [knitAnimationId]
        ),
        Skill(
            id: purlSkillId,
            ownerId: ownerId,
            name: "안뜨기",
            abbreviation: "P",
            description: "실을 앞쪽에 두고 코를 떠서 겉뜨기와 반대 방향의 질감을 만드는 기본 기법입니다.",
            category: "기본",
            difficulty: "초급",
            animationName: "안뜨기 기본 동작",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 4, day: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 10),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["실을 작업물 앞쪽에 둡니다.", "오른쪽 바늘을 오른쪽에서 왼쪽 방향으로 넣습니다.", "실을 감아 새 코를 빼냅니다."]
        ),
        Skill(
            id: castOnSkillId,
            ownerId: ownerId,
            name: "코 만들기",
            abbreviation: "CO",
            description: "프로젝트를 시작하기 위해 바늘 위에 첫 코들을 만드는 단계입니다.",
            category: "시작/마무리",
            difficulty: "초급",
            animationName: "코 만들기 흐름",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 4, day: 11),
            updatedAt: makeDate(year: 2026, month: 4, day: 11),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["도안에 적힌 코 수를 확인합니다.", "선택한 코 만들기 방법으로 코를 만듭니다.", "코가 너무 조이지 않도록 장력을 확인합니다."]
        ),
        Skill(
            id: bindOffSkillId,
            ownerId: ownerId,
            name: "코 막음",
            abbreviation: "BO",
            description: "마지막 단에서 코가 풀리지 않도록 마무리하는 방법입니다.",
            category: "시작/마무리",
            difficulty: "초급",
            animationName: "코 막음 흐름",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 4, day: 12),
            updatedAt: makeDate(year: 2026, month: 4, day: 12),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["두 코를 뜹니다.", "앞의 코를 뒤의 코 위로 넘깁니다.", "끝까지 반복한 뒤 실을 정리합니다."]
        ),
        Skill(
            id: yarnOverSkillId,
            ownerId: ownerId,
            name: "실 감기",
            abbreviation: "YO",
            description: "바늘에 실을 한 번 감아 구멍 무늬를 만들거나 코를 늘리는 기법입니다.",
            category: "무늬/늘림",
            difficulty: "초급",
            animationName: "실 감기 동작",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 4, day: 13),
            updatedAt: makeDate(year: 2026, month: 4, day: 13),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["작업 방향에 맞춰 실을 바늘 위로 감습니다.", "다음 코를 도안 지시대로 뜹니다.", "다음 단에서 감긴 실을 하나의 코로 처리합니다."]
        ),
        Skill(
            id: slipSkillId,
            ownerId: ownerId,
            name: "걸러뜨기",
            abbreviation: "SL",
            description: "코를 뜨지 않고 오른쪽 바늘로 옮기는 기법입니다. 가장자리 정리나 무늬 이동에 자주 사용됩니다.",
            category: "기본/무늬",
            difficulty: "초급",
            animationName: "걸러뜨기 동작",
            animationType: "placeholder",
            createdAt: makeDate(year: 2026, month: 4, day: 14),
            updatedAt: makeDate(year: 2026, month: 4, day: 14),
            deletedAt: nil,
            syncStatus: .localOnly,
            steps: ["도안의 지시대로 knitwise 또는 purlwise 방향을 확인합니다.", "코를 뜨지 않고 오른쪽 바늘로 옮깁니다.", "실 위치가 도안 지시와 맞는지 확인합니다."]
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
                memo: "두 번째 소매 작업 중. K, YO 구간 확인 후 다음 세션 시작.",
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
                relatedSkillIds: [knitSkillId, yarnOverSkillId],
                createdAt: makeDate(year: 2026, month: 4, day: 12),
                updatedAt: makeDate(year: 2026, month: 6, day: 1)
            ),
            KnittingProject(
                id: beanieProjectId,
                ownerId: ownerId,
                name: "Soft Ribbed Beanie",
                status: .planned,
                isFavorite: false,
                memo: "회색 메리노로 CO 96 예정. 게이지 스와치 먼저 만들기.",
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
                memo: "6번째 반복 후 잠시 멈춤. SL 가장자리와 K 구간 확인.",
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
                relatedSkillIds: [slipSkillId, knitSkillId],
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
