import SwiftUI

struct ProjectWorkSessionListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var editingSession: WorkSession?
    @State private var sessionPendingDeletion: WorkSession?
    @State private var memoText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.project.workSessions.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            statisticsSummary
                        }
                        .listRowStyle()

                        Section("세션") {
                            ForEach(viewModel.workSessionsByMostRecent) { session in
                                sessionRow(session)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        memoText = session.memo ?? ""
                                        editingSession = session
                                    }
                                    .contextMenu {
                                        Button {
                                            memoText = session.memo ?? ""
                                            editingSession = session
                                        } label: {
                                            Label("메모 수정", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            sessionPendingDeletion = session
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                    .listRowStyle()
                                    .accessibilityIdentifier(AppAccessibilityID.Workspace.workSessionRow(session.id))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Color.warmBackground)
                }
            }
            .warmScreenBackground()
            .navigationTitle("세션 내역")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingSession) { session in
                WorkSessionMemoEditSheet(
                    session: session,
                    memo: $memoText
                ) {
                    Task {
                        let didSave = await viewModel.updateWorkSessionMemo(
                            sessionID: session.id,
                            memo: memoText
                        )

                        if didSave {
                            editingSession = nil
                        }
                    }
                }
            }
            .alert("세션을 삭제할까요?", isPresented: deletionBinding) {
                Button("취소", role: .cancel) {
                    sessionPendingDeletion = nil
                }

                Button("삭제", role: .destructive) {
                    if let sessionPendingDeletion {
                        Task {
                            let didDelete = await viewModel.deleteWorkSession(sessionID: sessionPendingDeletion.id)
                            if didDelete {
                                self.sessionPendingDeletion = nil
                            }
                        }
                    }
                }
            } message: {
                Text("삭제한 작업시간은 누적 시간과 통계에서 빠져요.")
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "세션 기록이 없어요",
            description: "작업을 시작하면 세션 기록이 쌓여요.",
            systemImage: "clock"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var statisticsSummary: some View {
        let statistics = viewModel.workSessionStatistics

        return VStack(spacing: 10) {
            HStack(spacing: 0) {
                statItem(title: "오늘", value: WorkTimeFormatter.workTimeText(statistics.todayDuration))
                Divider().frame(height: 34)
                statItem(title: "총 작업", value: WorkTimeFormatter.workTimeText(statistics.totalDuration))
                Divider().frame(height: 34)
                statItem(title: "평균", value: WorkTimeFormatter.workTimeText(statistics.averageDuration))
            }

            Text("총 \(statistics.sessionCount)회")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .appCard()
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func sessionRow(_ session: WorkSession) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.startedAt.formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated)))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer(minLength: 12)

                Text(WorkTimeFormatter.workTimeText(session.duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(timeRangeText(for: session))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let memo = session.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("메모 없음")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { sessionPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    sessionPendingDeletion = nil
                }
            }
        )
    }

    private func timeRangeText(for session: WorkSession) -> String {
        let start = session.startedAt.formatted(.dateTime.hour().minute())

        guard let endedAt = session.endedAt else {
            return "\(start) - 진행 중"
        }

        let end = endedAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
    }
}

private struct WorkSessionMemoEditSheet: View {
    let session: WorkSession
    @Binding var memo: String
    let saveAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "세션",
                        description: "작업 시간을 확인하고 메모를 남겨요.",
                        systemImage: "timer",
                        tint: AppTheme.Color.accent
                    ) {
                        sessionInfoRow("시간", WorkTimeFormatter.workTimeText(session.duration), systemImage: "clock")
                        AppFormDivider()
                        sessionInfoRow(
                            "시작",
                            session.startedAt.formatted(.dateTime.month().day().hour().minute()),
                            systemImage: "calendar"
                        )
                    }

                    AppFormSection(
                        title: "메모",
                        description: "어느 부위를 작업했는지 적어두면 통계 확인이 쉬워요.",
                        systemImage: "note.text",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextFieldRow(
                            title: "작업 내용",
                            placeholder: "어떤 부분을 작업했나요?",
                            systemImage: "pencil.line",
                            text: $memo,
                            axis: .vertical,
                            minHeight: 120
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Workspace.workSessionMemoField)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle("세션 메모")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: false,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.workSessionMemoSaveButton
                ) {
                    saveAction()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sessionInfoRow(_ title: String, _ value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 22)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.primaryText)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}
