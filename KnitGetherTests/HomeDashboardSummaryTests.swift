import Foundation
import Testing
@testable import KnitGether

struct HomeDashboardSummaryTests {
    @Test func summaryCountsProjectsAndChoosesContinueProject() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let wipRecent = Self.makeProject(
            name: "Recent Sweater",
            status: .wip,
            isFavorite: false,
            lastWorkedAt: now.addingTimeInterval(-60),
            workDuration: 3_600
        )
        let wipFavorite = Self.makeProject(
            name: "Favorite Socks",
            status: .wip,
            isFavorite: true,
            lastWorkedAt: now.addingTimeInterval(-3_600),
            workDuration: 1_800
        )
        let finished = Self.makeProject(
            name: "Finished Shawl",
            status: .fo,
            isFavorite: false,
            lastWorkedAt: now.addingTimeInterval(-120),
            workDuration: 600
        )
        let planned = Self.makeProject(
            name: "Planned Vest",
            status: .planned,
            isFavorite: false,
            lastWorkedAt: nil,
            workDuration: 0
        )

        let summary = HomeDashboardSummary(
            profile: UserProfile(
                id: "user-a",
                ownerId: "user-a",
                displayName: "Yuha",
                preferredUnits: "Metric",
                createdAt: now,
                updatedAt: now,
                deletedAt: nil,
                syncStatus: .synced
            ),
            projects: [planned, finished, wipRecent, wipFavorite]
        )

        #expect(summary.displayName == "Yuha")
        #expect(summary.totalProjectCount == 4)
        #expect(summary.inProgressProjectCount == 2)
        #expect(summary.completedProjectCount == 1)
        #expect(summary.totalWorkTime == 6_000)
        #expect(summary.continueProject?.name == "Favorite Socks")
        #expect(summary.recentProjects.map(\.name) == ["Recent Sweater", "Finished Shawl", "Favorite Socks"])
    }

    private static func makeProject(
        name: String,
        status: ProjectStatus,
        isFavorite: Bool,
        lastWorkedAt: Date?,
        workDuration: TimeInterval
    ) -> KnittingProject {
        let projectID = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let session = WorkSession(
            ownerId: "user-a",
            projectId: projectID,
            startedAt: now.addingTimeInterval(-workDuration),
            endedAt: now,
            memo: nil,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
        let counter = RowCounter(
            ownerId: "user-a",
            projectId: projectID,
            sectionName: "Body",
            memo: nil,
            currentRow: 12,
            targetRow: 80,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )

        return KnittingProject(
            id: projectID,
            ownerId: "user-a",
            name: name,
            status: status,
            isFavorite: isFavorite,
            memo: "",
            startDate: now,
            lastWorkedAt: lastWorkedAt,
            patternCopy: nil,
            rowCounter: counter,
            workSessions: workDuration > 0 ? [session] : [],
            createdAt: now,
            updatedAt: lastWorkedAt ?? now,
            syncStatus: .synced
        )
    }
}
