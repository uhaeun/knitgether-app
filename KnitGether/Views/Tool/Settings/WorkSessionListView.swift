import SwiftUI

struct WorkSessionListView: View {
    private let projectRepository: any ProjectRepository

    @State private var projects: [KnittingProject] = []
    @State private var editingItem: SettingsWorkSessionItem?
    @State private var pendingDeletion: SettingsWorkSessionItem?
    @State private var memoText = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    init(projectRepository: any ProjectRepository) {
        self.projectRepository = projectRepository
    }

    var body: some View {
        List {
            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("세션을 불러오는 중이에요.")
                        .foregroundStyle(.secondary)
                }
                .listRowStyle()
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .listRowStyle()
            }

            Section("요약") {
                summaryCard
                    .listRowStyle()
            }

            Section("전체 세션") {
                if sessionItems.isEmpty {
                    EmptyStateView(
                        title: "작업 세션 기록이 없어요.",
                        description: "프로젝트 작업공간에서 작업 시작/종료를 사용하면 여기에 기록돼요.",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .listRowStyle()
                } else {
                    ForEach(sessionItems) { item in
                        sessionRow(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                memoText = item.session.memo ?? ""
                                editingItem = item
                            }
                            .contextMenu {
                                Button {
                                    memoText = item.session.memo ?? ""
                                    editingItem = item
                                } label: {
                                    Label("메모 수정", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    pendingDeletion = item
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                            .listRowStyle()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("작업 세션 목록")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProjects()
        }
        .refreshable {
            await loadProjects()
        }
        .sheet(item: $editingItem) { item in
            WorkSessionMemoSheet(
                item: item,
                memo: $memoText
            ) {
                Task {
                    await updateMemo(for: item)
                }
            }
        }
        .alert("세션을 삭제할까요?", isPresented: deletionBinding) {
            Button("취소", role: .cancel) {
                pendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                if let pendingDeletion {
                    Task {
                        await deleteSession(pendingDeletion)
                    }
                }
            }
        } message: {
            Text("삭제한 세션은 프로젝트 누적 작업시간과 통계에서 빠져요.")
        }
    }

    private var sessionItems: [SettingsWorkSessionItem] {
        projects
            .flatMap { project in
                project.workSessions.map { session in
                    SettingsWorkSessionItem(project: project, session: session)
                }
            }
            .sorted { first, second in
                if first.session.startedAt == second.session.startedAt {
                    return first.session.id.uuidString < second.session.id.uuidString
                }
                return first.session.startedAt > second.session.startedAt
            }
    }

    private var statistics: WorkSessionStatistics {
        WorkSessionStatistics(sessions: sessionItems.map(\.session))
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                statItem(title: "총 작업", value: WorkTimeFormatter.workTimeText(statistics.totalDuration))
                Divider().frame(height: 34)
                statItem(title: "오늘", value: WorkTimeFormatter.workTimeText(statistics.todayDuration))
            }

            Divider()

            HStack(spacing: 0) {
                statItem(title: "세션", value: "\(statistics.sessionCount)회")
                Divider().frame(height: 34)
                statItem(title: "평균", value: WorkTimeFormatter.workTimeText(statistics.averageDuration))
            }
        }
        .padding(12)
        .appCard()
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

    private func sessionRow(_ item: SettingsWorkSessionItem) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.projectName)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(WorkTimeFormatter.workTimeText(item.session.duration))
                    .font(.subheadline.bold())
                    .monospacedDigit()
            }

            Text(item.dateRangeText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let memo = item.session.memo, !memo.isEmpty {
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
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletion = nil
                }
            }
        )
    }

    private func loadProjects() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "작업 세션을 불러오지 못했어요."
        }
    }

    private func updateMemo(for item: SettingsWorkSessionItem) async {
        let trimmedMemo = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedSession = item.session.updatingMemo(trimmedMemo.isEmpty ? nil : trimmedMemo)

        do {
            let savedSession = try await projectRepository.saveWorkSession(
                updatedSession,
                forProjectId: item.projectId
            )
            updateLocalSession(savedSession, inProjectId: item.projectId)
            editingItem = nil
            errorMessage = nil
        } catch {
            errorMessage = "세션 메모를 저장하지 못했어요."
        }
    }

    private func deleteSession(_ item: SettingsWorkSessionItem) async {
        do {
            try await projectRepository.deleteWorkSession(id: item.session.id, forProjectId: item.projectId)
            if let projectIndex = projects.firstIndex(where: { $0.id == item.projectId }) {
                projects[projectIndex] = projects[projectIndex].copy(
                    workSessions: projects[projectIndex].workSessions.filter { $0.id != item.session.id },
                    updatedAt: Date()
                )
            }
            pendingDeletion = nil
            errorMessage = nil
        } catch {
            errorMessage = "세션을 삭제하지 못했어요."
        }
    }

    private func updateLocalSession(_ session: WorkSession, inProjectId projectId: UUID) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }

        let project = projects[projectIndex]
        let updatedSessions = project.workSessions.map { existingSession in
            existingSession.id == session.id ? session : existingSession
        }
        projects[projectIndex] = project.copy(workSessions: updatedSessions, updatedAt: Date())
    }
}

private struct SettingsWorkSessionItem: Identifiable, Hashable {
    let projectId: UUID
    let projectName: String
    let session: WorkSession

    var id: UUID {
        session.id
    }

    init(project: KnittingProject, session: WorkSession) {
        projectId = project.id
        projectName = project.name
        self.session = session
    }

    var dateRangeText: String {
        let date = session.startedAt.formatted(.dateTime.year().month().day())
        let start = session.startedAt.formatted(.dateTime.hour().minute())
        let end = (session.endedAt ?? session.startedAt).formatted(.dateTime.hour().minute())
        return "\(date) · \(start) - \(end)"
    }
}

private struct WorkSessionMemoSheet: View {
    let item: SettingsWorkSessionItem
    @Binding var memo: String
    let saveAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "세션",
                        description: "전체 작업 시간 통계에 반영되는 기록이에요.",
                        systemImage: "timer",
                        tint: AppTheme.Color.accent
                    ) {
                        sessionInfoRow("프로젝트", item.projectName, systemImage: "folder")
                        AppFormDivider()
                        sessionInfoRow("시간", WorkTimeFormatter.workTimeText(item.session.duration), systemImage: "clock")
                        AppFormDivider()
                        sessionInfoRow(
                            "시작",
                            item.session.startedAt.formatted(.dateTime.month().day().hour().minute()),
                            systemImage: "calendar"
                        )
                    }

                    AppFormSection(
                        title: "메모",
                        description: "나중에 작업 내역을 되짚어볼 수 있게 남겨요.",
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
                AppFormSubmitBar(title: "저장", isDisabled: false) {
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
