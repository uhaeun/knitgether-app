//
//  HomeView.swift
//  KnitGether
//
//  Created by Codex on 7/10/26.
//

import Combine
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeDashboardViewModel
    @ObservedObject private var authSessionStore: AuthSessionStore

    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository
    private let libraryRepository: any LibraryRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let progressPhotoRepository: any ProjectProgressPhotoRepository
    private let dictionaryRepository: any DictionaryRepository

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: HomeDashboardViewModel(
                profileRepository: repositories.profileRepository,
                projectRepository: repositories.projectRepository
            )
        )
        authSessionStore = repositories.authSessionStore
        projectRepository = repositories.projectRepository
        patternRepository = repositories.patternRepository
        skillRepository = repositories.skillRepository
        libraryRepository = repositories.libraryRepository
        gaugeRecordRepository = repositories.gaugeRecordRepository
        progressPhotoRepository = repositories.progressPhotoRepository
        dictionaryRepository = repositories.dictionaryRepository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsGrid

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }

                if let project = viewModel.summary.continueProject {
                    continueSection(project: project)
                } else {
                    emptyContinueSection
                }

                recentSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .warmScreenBackground()
        .navigationTitle("홈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("홈 새로고침")
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onReceive(authSessionStore.$currentSession.dropFirst()) { _ in
            Task {
                await viewModel.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(Date().formatted(.dateTime.month().day().weekday(.wide)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("안녕하세요, \(viewModel.summary.displayName)님")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(AppTheme.Color.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
            ],
            spacing: AppTheme.Spacing.sm
        ) {
            HomeStatTile(
                title: "전체 프로젝트",
                value: "\(viewModel.summary.totalProjectCount)",
                systemImage: "folder"
            )
            HomeStatTile(
                title: "진행 중",
                value: "\(viewModel.summary.inProgressProjectCount)",
                systemImage: "play.circle"
            )
            HomeStatTile(
                title: "완성됨",
                value: "\(viewModel.summary.completedProjectCount)",
                systemImage: "checkmark.seal"
            )
            HomeStatTile(
                title: "누적 작업",
                value: WorkTimeFormatter.workTimeText(viewModel.summary.totalWorkTime),
                systemImage: "timer"
            )
        }
    }

    private func continueSection(project: KnittingProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("이어서 뜨기")

            NavigationLink {
                workspace(for: project)
            } label: {
                HomeProjectCard(project: project, isPrimary: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyContinueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("이어서 뜨기")

            HStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("진행 중인 프로젝트가 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .appCard(cornerRadius: 20)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("최근 작업")

            if viewModel.summary.recentProjects.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("아직 작업 기록이 없어요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding()
                .appCard(cornerRadius: 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.summary.recentProjects) { project in
                        NavigationLink {
                            workspace(for: project)
                        } label: {
                            HomeProjectCard(project: project, isPrimary: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.Color.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)

            Spacer()

            Button {
                Task {
                    await viewModel.load()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .appCard(cornerRadius: 20)
    }

    private func workspace(for project: KnittingProject) -> some View {
        ProjectWorkspaceView(
            viewModel: ProjectWorkspaceViewModel(
                project: project,
                projectRepository: projectRepository,
                patternRepository: patternRepository,
                skillRepository: skillRepository,
                libraryRepository: libraryRepository,
                gaugeRecordRepository: gaugeRecordRepository,
                progressPhotoRepository: progressPhotoRepository
            ),
            dictionaryRepository: dictionaryRepository,
            skillRepository: skillRepository
        )
    }
}

private struct HomeStatTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(14)
        .appCard(cornerRadius: 18)
    }
}

private struct HomeProjectCard: View {
    let project: KnittingProject
    let isPrimary: Bool

    var body: some View {
        let statusColors = AppTheme.statusColorSoft(for: project.status)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isPrimary ? "arrow.forward.circle.fill" : "doc.text")
                    .font(isPrimary ? .title2 : .title3)
                    .foregroundStyle(isPrimary ? .white : AppTheme.Color.accent)
                    .frame(width: isPrimary ? 44 : 36, height: isPrimary ? 44 : 36)
                    .background(isPrimary ? Color.white.opacity(0.18) : AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: isPrimary ? 14 : 11, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(project.name)
                            .font(isPrimary ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                            .foregroundStyle(isPrimary ? .white : AppTheme.Color.primaryText)
                            .lineLimit(1)

                        if project.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(isPrimary ? .white.opacity(0.85) : Color(red: 0.788, green: 0.647, blue: 0.353))
                        }
                    }

                    HStack(spacing: 8) {
                        Text(project.status.badgeTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isPrimary ? Color.white.opacity(0.18) : statusColors.bg)
                            .foregroundStyle(isPrimary ? .white : statusColors.fg)
                            .clipShape(Capsule())

                        Text(projectTimelineText)
                            .font(.caption)
                            .foregroundStyle(isPrimary ? .white.opacity(0.78) : .secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isPrimary ? .white.opacity(0.75) : .secondary.opacity(0.55))
            }

            if isPrimary, let progressValue {
                ProgressView(value: progressValue)
                    .tint(.white)
                    .progressViewStyle(.linear)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 18 : 14)
        .background(
            isPrimary ? AppTheme.Color.softAccent : AppTheme.Color.cardBackground,
            in: RoundedRectangle(cornerRadius: isPrimary ? 24 : 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: isPrimary ? 24 : 18, style: .continuous)
                .stroke(isPrimary ? Color.white.opacity(0.2) : AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .shadow(color: .black.opacity(AppTheme.Card.shadowOpacity), radius: AppTheme.Card.shadowRadius, y: AppTheme.Card.shadowY)
    }

    private var projectTimelineText: String {
        guard let lastWorkedAt = project.lastWorkedAt else {
            return "작업 기록 없음"
        }

        return lastWorkedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var progressValue: Double? {
        guard let targetRow = project.rowCounter.targetRow, targetRow > 0 else {
            return nil
        }

        return min(max(Double(project.rowCounter.currentRow) / Double(targetRow), 0), 1)
    }
}

#Preview {
    NavigationStack {
        HomeView(repositories: .shared)
    }
}
