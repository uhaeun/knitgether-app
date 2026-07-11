import SwiftUI

struct ProjectWorkspaceSummaryView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        WorkspaceSectionView(title: "프로젝트 요약", systemImage: "list.bullet.rectangle") {
            VStack(spacing: 10) {
                summaryRow(title: "화면 구성", value: viewModel.displayMode.title)
                summaryRow(title: "도안", value: patternStatusText)
                summaryRow(title: "재료", value: viewModel.project.materialSummaryText)
                summaryRow(title: "실 사용", value: viewModel.yarnUsageSummaryText)
                summaryRow(title: "카운터", value: counterStatusText)
                summaryRow(title: "행안내", value: rowGuideStatusText)
                summaryRow(title: "일정", value: scheduleStatusText)
                summaryRow(title: "서버 저장", value: viewModel.project.syncStatus.displayTitle)
            }
        }
    }

    private var patternStatusText: String {
        guard let patternCopy = viewModel.project.patternCopy else {
            return "연결 없음"
        }

        if patternCopy.fileNameSnapshot == nil {
            return "\(patternCopy.titleSnapshot) · 수동"
        }

        return patternCopy.titleSnapshot
    }

    private var counterStatusText: String {
        if let targetRow = viewModel.rowCounter.targetRow {
            return "\(viewModel.currentRow) / \(targetRow)단"
        }

        return "\(viewModel.currentRow)단 · 총 단수 미설정"
    }

    private var rowGuideStatusText: String {
        guard viewModel.rowCounter.mode == .rowGuide else {
            return "간편 모드"
        }

        let count = viewModel.rowCounter.rowInstructions.count
        return count == 0 ? "행안내 없음" : "\(count)개 등록"
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
