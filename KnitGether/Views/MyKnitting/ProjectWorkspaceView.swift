//
//  ProjectWorkspaceView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ProjectWorkspaceView: View {
    @StateObject private var viewModel: ProjectWorkspaceViewModel

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
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRelatedSkills()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusBadgeView(status: viewModel.project.status)

            Text(viewModel.project.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }

    private var patternSection: some View {
        WorkspaceSectionView(title: "Pattern Area", systemImage: "doc.text.magnifyingglass") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Pattern Mode", selection: $viewModel.interactionMode) {
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

                    Text("Project-owned snapshot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("PDF viewer and drawing overlay will be implemented here next.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var patternMissingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("No pattern is attached to this project.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)

            HStack {
                Button {
                } label: {
                    Label("Add Pattern", systemImage: "plus")
                }

                Button {
                } label: {
                    Label("Import from Library", systemImage: "books.vertical")
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var rowCounterSection: some View {
        WorkspaceSectionView(title: "Row Counter", systemImage: "number.square") {
            HStack(spacing: 18) {
                Button {
                    viewModel.decrementRow()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                }
                .disabled(viewModel.currentRow == 0)
                .accessibilityLabel("Decrease row")

                VStack(spacing: 4) {
                    Text("Current Row")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(viewModel.currentRow)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)

                Button {
                    viewModel.incrementRow()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                }
                .accessibilityLabel("Increase row")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
    }

    private var memoSection: some View {
        WorkspaceSectionView(title: "Work Memo", systemImage: "note.text") {
            Text(viewModel.project.memo)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private var workTimeSection: some View {
        WorkspaceSectionView(title: "Work Time Tracking", systemImage: "timer") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total: \(formattedDuration(viewModel.project.totalWorkTime))")
                    .font(.headline)

                Button {
                    viewModel.toggleWorkTimer()
                } label: {
                    Label(
                        viewModel.isTrackingTime ? "Stop Timer" : "Start Timer",
                        systemImage: viewModel.isTrackingTime ? "stop.circle" : "play.circle"
                    )
                }
                .buttonStyle(.borderedProminent)

                Text("Session persistence will be added after the local storage layer is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var relatedSkillsSection: some View {
        WorkspaceSectionView(title: "Related Skills", systemImage: "graduationcap") {
            if viewModel.relatedSkills.isEmpty {
                Text("No related skills linked yet.")
                    .foregroundStyle(.secondary)
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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
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
