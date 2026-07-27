import SwiftUI

struct ProjectWorkspaceSummaryView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        // 도안·재료·실사용·행안내·서버저장은 정보 탭의 개별 패널/헤더 배지와 중복이라 제외하고,
        // 한눈에 볼 지표(진행·일정)와 헤더에서 옮겨온 참고값(시작일·총 작업시간)만 남긴다.
        WorkspaceSectionView(title: "프로젝트 요약", systemImage: "list.bullet.rectangle") {
            VStack(spacing: 10) {
                summaryRow(title: "진행", value: counterStatusText)
                summaryRow(title: "일정", value: scheduleStatusText)
                summaryRow(title: "시작일", value: startDateText)
                summaryRow(title: "총 작업시간", value: totalWorkTimeText)
            }
        }
    }

    private var counterStatusText: String {
        if let targetRow = viewModel.rowCounter.targetRow {
            return "\(viewModel.currentRow) / \(targetRow)단"
        }

        return "\(viewModel.currentRow)단 · 총 단수 미설정"
    }

    private var startDateText: String {
        formattedDate(viewModel.project.startDate)
    }

    private var totalWorkTimeText: String {
        let totalSeconds = max(0, Int(viewModel.project.totalWorkTime.rounded()))
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

    private var scheduleStatusText: String {
        if let finishedAt = viewModel.project.finishedAt {
            return "완료 \(formattedDate(finishedAt))"
        }

        guard let days = viewModel.project.daysUntilTarget() else {
            return "목표일 없음"
        }

        if days > 0 {
            return "D-\(days)"
        }

        if days == 0 {
            return "D-Day"
        }

        return "D+\(-days)"
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.Color.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.month().day())
    }
}
