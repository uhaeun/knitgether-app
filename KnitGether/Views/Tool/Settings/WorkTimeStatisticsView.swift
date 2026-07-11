import SwiftUI

struct WorkTimeStatisticsView: View {
    private let projectRepository: any ProjectRepository
    @State private var projects: [KnittingProject] = []
    @State private var errorMessage: String?

    init(projectRepository: any ProjectRepository) {
        self.projectRepository = projectRepository
    }

    private var summary: SettingsWorkTimeSummary {
        SettingsWorkTimeSummary(projects: projects)
    }

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .listRowStyle()
            }

            Section("요약") {
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        statItem(title: "총 작업", value: WorkTimeFormatter.workTimeText(summary.statistics.totalDuration))
                        Divider().frame(height: 34)
                        statItem(title: "오늘", value: WorkTimeFormatter.workTimeText(summary.statistics.todayDuration))
                    }

                    Divider()

                    HStack(spacing: 0) {
                        statItem(title: "세션", value: "\(summary.statistics.sessionCount)회")
                        Divider().frame(height: 34)
                        statItem(title: "평균", value: WorkTimeFormatter.workTimeText(summary.statistics.averageDuration))
                    }
                }
                .padding(12)
                .appCard()
                .listRowStyle()
            }

            Section("프로젝트별 작업시간") {
                if summary.topProjects.isEmpty {
                    Text("작업시간 기록이 없어요.")
                        .foregroundStyle(.secondary)
                        .listRowStyle()
                } else {
                    ForEach(summary.topProjects, id: \.id) { item in
                        HStack {
                            Text(item.name)
                                .lineLimit(1)
                            Spacer()
                            Text(WorkTimeFormatter.workTimeText(item.duration))
                                .font(.subheadline.bold())
                        }
                        .padding(12)
                        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
                        }
                        .listRowStyle()
                    }
                }
            }

            Section("최근 세션") {
                if summary.sessionsByMostRecent.isEmpty {
                    Text("세션 기록이 없어요.")
                        .foregroundStyle(.secondary)
                        .listRowStyle()
                } else {
                    ForEach(summary.sessionsByMostRecent.prefix(20), id: \.id) { session in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(session.startedAt.formatted(.dateTime.year().month().day()))
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(WorkTimeFormatter.workTimeText(session.duration))
                                    .font(.subheadline.bold())
                            }

                            Text("\(session.startedAt.formatted(.dateTime.hour().minute())) - \((session.endedAt ?? session.startedAt).formatted(.dateTime.hour().minute()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let memo = session.memo, !memo.isEmpty {
                                Text(memo)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                }
                        }
                        .padding(12)
                        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
                        }
                        .listRowStyle()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("작업시간 통계")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProjects()
        }
        .refreshable {
            await loadProjects()
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadProjects() async {
        do {
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "작업시간 통계를 불러오지 못했어요."
        }
    }
}
