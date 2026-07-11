import Foundation
import Testing
@testable import KnitGether

struct SettingsStatisticsTests {
    @Test func workTimeSummaryAggregatesSessionsAcrossProjects() async throws {
        let projectA = Self.makeProject(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            name: "Cardigan",
            sessions: [
                Self.makeSession(
                    projectId: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
                    startedAt: Date(timeIntervalSince1970: 1_800_000_000),
                    endedAt: Date(timeIntervalSince1970: 1_800_003_600)
                )
            ]
        )
        let projectB = Self.makeProject(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            name: "Scarf",
            sessions: [
                Self.makeSession(
                    projectId: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
                    startedAt: Date(timeIntervalSince1970: 1_799_900_000),
                    endedAt: Date(timeIntervalSince1970: 1_799_901_800)
                )
            ]
        )

        let summary = SettingsWorkTimeSummary(
            projects: [projectB, projectA],
            referenceDate: Date(timeIntervalSince1970: 1_800_000_500)
        )

        #expect(summary.statistics.sessionCount == 2)
        #expect(summary.statistics.totalDuration == 5_400)
        #expect(summary.statistics.todayDuration == 3_600)
        #expect(summary.topProjects.map(\.name) == ["Cardigan", "Scarf"])
        #expect(summary.topProjects.map(\.duration) == [3_600, 1_800])
    }

    private static func makeProject(
        id: UUID,
        name: String,
        sessions: [WorkSession]
    ) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return KnittingProject(
            id: id,
            ownerId: "user-a",
            name: name,
            status: .wip,
            isFavorite: false,
            memo: "",
            startDate: now,
            lastWorkedAt: now,
            patternCopy: nil,
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: id,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now
            ),
            workSessions: sessions,
            createdAt: now,
            updatedAt: now
        )
    }

    private static func makeSession(
        projectId: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> WorkSession {
        WorkSession(
            ownerId: "user-a",
            projectId: projectId,
            startedAt: startedAt,
            endedAt: endedAt,
            memo: nil,
            createdAt: startedAt,
            updatedAt: endedAt,
            syncStatus: .synced
        )
    }
}
