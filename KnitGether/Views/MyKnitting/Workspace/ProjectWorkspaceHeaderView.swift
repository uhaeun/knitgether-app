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

            // 시작일·총 작업시간·일정은 프로젝트 정보 탭의 요약으로 옮겨 헤더를 간결하게 유지한다.
            metadata(title: "최근 작업", value: formattedDate(viewModel.project.lastWorkedAt))

            if viewModel.project.syncStatus.needsSync {
                SyncRetryBanner(
                    message: viewModel.project.syncStatus.detailText,
                    isRetrying: viewModel.isRetryingSync,
                    retryAction: {
                        Task {
                            await viewModel.retrySync()
                        }
                    }
                )
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
}
