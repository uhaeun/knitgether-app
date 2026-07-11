import SwiftUI

struct ProjectWorkTimePanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    let startAction: () -> Void
    let finishAction: () -> Void
    let showSessionsAction: () -> Void

    var body: some View {
        WorkspaceSectionView(title: "작업 시간", systemImage: "timer") {
            VStack(alignment: .leading, spacing: 14) {
                AppSoftPanel {
                    HStack(spacing: 16) {
                        metadata(title: "이번 작업", value: WorkTimeFormatter.workTimeText(viewModel.currentSessionElapsed))
                        metadata(title: "누적 작업", value: WorkTimeFormatter.workTimeText(viewModel.project.totalWorkTime))
                    }
                }

                AppSoftPanel {
                    HStack(spacing: 16) {
                        metadata(title: "오늘 작업", value: WorkTimeFormatter.workTimeText(viewModel.workSessionStatistics.todayDuration))
                        metadata(title: "평균 세션", value: WorkTimeFormatter.workTimeText(viewModel.workSessionStatistics.averageDuration))
                    }
                }

                AppSoftPanel {
                    HStack(spacing: 10) {
                        Label(
                            viewModel.isTrackingTime ? "작업 시간을 기록 중이에요." : "작업 시간이 멈춰 있어요.",
                            systemImage: viewModel.isTrackingTime ? "record.circle" : "pause.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(viewModel.isTrackingTime ? AppTheme.Color.rose : .secondary)

                        Spacer()

                        if viewModel.isTrackingTime {
                            Button {
                                finishAction()
                            } label: {
                                Label("작업 종료", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier(AppAccessibilityID.Workspace.workFinishButton)
                        } else {
                            Button {
                                startAction()
                            } label: {
                                Label("작업 시작", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.Color.accent)
                            .accessibilityIdentifier(AppAccessibilityID.Workspace.workStartButton)
                        }
                    }
                }

                Button {
                    showSessionsAction()
                } label: {
                    HStack {
                        Label("세션 내역", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text("\(viewModel.workSessionStatistics.sessionCount)회")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .disabled(viewModel.project.workSessions.isEmpty)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.workSessionsButton)
                .padding(12)
                .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
                }
            }
        }
    }

    private func metadata(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
