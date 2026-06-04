//
//  ProjectWorkspaceView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ProjectWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingEditProject = false

    init(viewModel: ProjectWorkspaceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                patternSection
                rowCounterSection
                memoSection
                workTimeSection
                relatedSkillsSection
            }
            .padding()
        }
        .navigationTitle("작업 공간")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    isShowingEditProject = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditProject) {
            EditProjectView(
                project: viewModel.project,
                onSave: { formData in
                    Task {
                        await viewModel.updateProject(with: formData)
                    }
                },
                onDelete: {
                    Task {
                        let didDelete = await viewModel.deleteProject()

                        if didDelete {
                            dismiss()
                        }
                    }
                }
            )
        }
        .task {
            viewModel.startWorkSession()
            await viewModel.loadRelatedSkills()

            while !Task.isCancelled {
                viewModel.refreshCurrentSessionElapsed()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        .onDisappear {
            Task {
                await viewModel.finishWorkSession()
            }
        }
    }

    private var header: some View {
        WorkspaceSectionView(title: "프로젝트", systemImage: "folder") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.project.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        StatusBadgeView(status: viewModel.project.status)
                    }

                    Spacer()

                    Image(systemName: viewModel.project.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(viewModel.project.isFavorite ? .yellow : .secondary)
                        .accessibilityLabel(viewModel.project.isFavorite ? "즐겨찾기" : "즐겨찾기 아님")
                }

                HStack(spacing: 14) {
                    metadata(title: "시작일", value: formattedDate(viewModel.project.startDate))
                    metadata(title: "최근 작업", value: formattedDate(viewModel.project.lastWorkedAt))
                    metadata(title: "총 작업 시간", value: formattedDuration(viewModel.project.totalWorkTime))
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

    private var patternSection: some View {
        WorkspaceSectionView(title: "도안", systemImage: "doc.text.magnifyingglass") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("도안 모드", selection: $viewModel.interactionMode) {
                    ForEach(PatternInteractionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if let patternCopy = viewModel.project.patternCopy {
                    patternAttachedView(patternCopy)
                } else {
                    patternMissingView
                }

                patternActionButtons
            }
        }
    }

    private func patternAttachedView(_ patternCopy: ProjectPatternCopy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(patternCopy.titleSnapshot)
                        .font(.headline)

                    Text("프로젝트에 저장된 도안 사본")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("다음 단계에서 PDF 뷰어와 그리기 레이어가 이 영역에 들어갑니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var patternMissingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("도안 없음", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }

    private var patternActionButtons: some View {
        HStack {
            Button {
            } label: {
                Label("도안 추가", systemImage: "plus")
            }

            Button {
            } label: {
                Label("Library에서 가져오기", systemImage: "books.vertical")
            }
        }
        .buttonStyle(.bordered)
    }

    private var rowCounterSection: some View {
        WorkspaceSectionView(title: "단수 카운터", systemImage: "number.square") {
            HStack(spacing: 18) {
                Button {
                    Task {
                        await viewModel.decrementRow()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                }
                .disabled(viewModel.currentRow == 0)
                .accessibilityLabel("단수 줄이기")

                VStack(spacing: 4) {
                    Text("현재 단수")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(viewModel.currentRow)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)

                Button {
                    Task {
                        await viewModel.incrementRow()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                }
                .accessibilityLabel("단수 늘리기")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
    }

    private var memoSection: some View {
        WorkspaceSectionView(title: "작업 메모", systemImage: "note.text") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.memoText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    Task {
                        await viewModel.saveMemo()
                    }
                } label: {
                    Label("저장", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasUnsavedMemoChanges)
            }
        }
    }

    private var workTimeSection: some View {
        WorkspaceSectionView(title: "작업 시간", systemImage: "timer") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("이번 작업 시간")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(formattedDuration(viewModel.currentSessionElapsed))
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("총 작업 시간")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(formattedDuration(viewModel.project.totalWorkTime))
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                Label(
                    viewModel.isTrackingTime ? "작업 시간을 기록 중이에요." : "작업 시간이 기록되지 않고 있어요.",
                    systemImage: viewModel.isTrackingTime ? "record.circle" : "pause.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var relatedSkillsSection: some View {
        WorkspaceSectionView(title: "관련 스킬", systemImage: "graduationcap") {
            if viewModel.relatedSkills.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("아직 연결된 스킬이 없어요.")
                        .foregroundStyle(.secondary)

                    Text("나중에 도안의 뜨개 용어를 분석해 설명과 애니메이션을 연결할 수 있습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.relatedSkills) { skill in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(skill.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "없음"
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year())
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

#Preview {
    NavigationStack {
        ProjectWorkspaceView(
            viewModel: ProjectWorkspaceViewModel(
                project: SampleData.projects[0],
                projectRepository: AppRepositoryContainer.shared.projectRepository,
                skillRepository: AppRepositoryContainer.shared.skillRepository
            )
        )
    }
}
