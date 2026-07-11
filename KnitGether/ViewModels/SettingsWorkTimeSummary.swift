import Foundation

struct SettingsProjectWorkTime: Hashable {
    let id: UUID
    let name: String
    let duration: TimeInterval
}

struct SettingsWorkTimeSummary: Hashable {
    let statistics: WorkSessionStatistics
    let topProjects: [SettingsProjectWorkTime]
    let sessionsByMostRecent: [WorkSession]

    init(
        projects: [KnittingProject],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) {
        let sessions = projects.flatMap(\.workSessions)
        statistics = WorkSessionStatistics(
            sessions: sessions,
            calendar: calendar,
            referenceDate: referenceDate
        )
        topProjects = projects
            .map { project in
                SettingsProjectWorkTime(
                    id: project.id,
                    name: project.name,
                    duration: project.workSessions.reduce(0) { $0 + $1.duration }
                )
            }
            .filter { $0.duration > 0 }
            .sorted { first, second in
                if first.duration == second.duration {
                    return first.name.localizedStandardCompare(second.name) == .orderedAscending
                }
                return first.duration > second.duration
            }
        sessionsByMostRecent = sessions.sorted { first, second in
            if first.startedAt == second.startedAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.startedAt > second.startedAt
        }
    }
}
