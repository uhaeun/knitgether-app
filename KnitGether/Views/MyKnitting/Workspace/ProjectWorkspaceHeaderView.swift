import SwiftUI

struct ProjectWorkspaceHeaderView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.project.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppTheme.Color.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        StatusBadgeView(status: viewModel.project.status)
                        if viewModel.project.syncStatus != .synced {
                            SyncStatusBadgeView(status: viewModel.project.syncStatus)
                        }
                    }
                }

                Spacer()

                Image(systemName: viewModel.project.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(viewModel.project.isFavorite ? Color(red: 0.788, green: 0.647, blue: 0.353) : .secondary.opacity(0.55))
                    .accessibilityLabel(viewModel.project.isFavorite ? "즐겨찾기" : "즐겨찾기 아님")
            }

            HStack(spacing: 14) {
                metadata(title: "시작일", value: formattedDate(viewModel.project.startDate))
                metadata(title: "최근 작업", value: formattedDate(viewModel.project.lastWorkedAt))
                metadata(title: "총 작업 시간", value: formattedDuration(viewModel.project.totalWorkTime))
            }

            if viewModel.project.targetDate != nil || viewModel.project.finishedAt != nil {
                Label(scheduleStatusText, systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(scheduleColor)
            }

            if viewModel.project.syncStatus.needsSync {
                HStack(alignment: .center, spacing: 12) {
                    Label(viewModel.project.syncStatus.detailText, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        Task {
                            await viewModel.retrySync()
                        }
                    } label: {
                        if viewModel.isRetryingSync {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("다시 시도", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.isRetryingSync)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 24)
    }

    private func metadata(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Color.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "없음"
        }

        return date.formatted(.dateTime.month().day())
    }

    private var scheduleStatusText: String {
        if let finishedAt = viewModel.project.finishedAt {
            return "완료일 \(formattedDate(finishedAt))"
        }

        guard let days = viewModel.project.daysUntilTarget() else {
            return "목표일 없음"
        }

        if days > 0 {
            return "목표일까지 D-\(days)"
        }

        if days == 0 {
            return "목표일 D-Day"
        }

        return "목표일 D+\(-days)"
    }

    private var scheduleColor: Color {
        if viewModel.project.finishedAt != nil {
            return .green
        }

        guard let days = viewModel.project.daysUntilTarget() else {
            return .secondary
        }

        return days < 0 ? .red : .secondary
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        }

        return "\(seconds)초"
    }
}
