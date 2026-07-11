//
//  MyKnittingView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI
import Combine

struct MyKnittingView: View {
    @StateObject private var viewModel: MyKnittingViewModel
    @ObservedObject private var authSessionStore: AuthSessionStore
    @State private var isShowingAddProject = false
    @State private var editingProject: KnittingProject?
    @State private var projectPendingDeletion: KnittingProject?
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedStatusFilter: ProjectStatus?

    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository
    private let libraryRepository: any LibraryRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let progressPhotoRepository: any ProjectProgressPhotoRepository
    private let dictionaryRepository: any DictionaryRepository

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: MyKnittingViewModel(
                projectRepository: repositories.projectRepository,
                patternRepository: repositories.patternRepository,
                libraryRepository: repositories.libraryRepository
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
        Group {
            if viewModel.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
        .navigationTitle("나의 뜨개")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasProjectsNeedingSync {
                    Button {
                        Task {
                            await viewModel.retrySync()
                        }
                    } label: {
                        if viewModel.isRetryingSync {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(viewModel.isRetryingSync)
                    .accessibilityLabel("프로젝트 저장 상태 다시 확인")
                }

                Button {
                    isShowingAddProject = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Project.addButton)
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddProject) {
            AddProjectView(
                availablePatterns: viewModel.availablePatterns,
                availableYarns: viewModel.availableYarns,
                availableNeedles: viewModel.availableNeedles
            ) { formData in
                await viewModel.addProject(from: formData)
            }
        }
        .sheet(item: $editingProject) { project in
            EditProjectView(
                project: project,
                availableYarns: viewModel.availableYarns,
                availableNeedles: viewModel.availableNeedles,
                onSave: { formData in
                    await viewModel.updateProject(project, with: formData)
                },
                onDelete: {
                    await viewModel.deleteProject(project)
                }
            )
        }
        .alert("프로젝트를 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: projectPendingDeletion) { project in
            Button("취소", role: .cancel) {
                projectPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteProject(project)

                    if didDelete {
                        projectPendingDeletion = nil
                    }
                }
            }
        } message: { _ in
            Text("삭제한 프로젝트는 복구할 수 없어요.")
        }
        .onAppear {
            Task {
                await viewModel.loadProjects()
                await viewModel.loadProjectPatterns()
                await viewModel.loadProjectMaterials()
            }
        }
        .refreshable {
            await viewModel.loadProjects()
            await viewModel.loadProjectPatterns()
            await viewModel.loadProjectMaterials()
        }
        .onReceive(authSessionStore.$currentSession.dropFirst()) { _ in
            Task {
                await viewModel.reloadAfterAccountChange()
            }
        }
    }

    private var projectList: some View {
        List {
            headerRow

            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
            }

            if viewModel.hasProjectsNeedingSync {
                syncRetryRow
            }

            ForEach(filteredProjects) { project in
                NavigationLink {
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
                } label: {
                    ProjectCardView(project: project)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppAccessibilityID.Project.row(project.id))
                .contextMenu {
                    Button {
                        editingProject = project
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        projectPendingDeletion = project
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        projectPendingDeletion = project
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }

                    Button {
                        editingProject = project
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .warmScreenBackground()
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("나의 뜨개")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(AppTheme.Color.primaryText)

                    Text("\(viewModel.projects.count)개 프로젝트")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "전체", status: nil)

                    ForEach(ProjectStatus.allCases) { status in
                        filterChip(title: status.badgeTitle, status: status)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 6)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
        .listRowBackground(Color.clear)
    }

    private func filterChip(title: String, status: ProjectStatus?) -> some View {
        let isSelected = selectedStatusFilter == status

        return Button {
            selectedStatusFilter = status
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.Color.primaryText.opacity(0.72))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.Color.accent : AppTheme.Color.cardBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.Color.warmDivider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 프로젝트 필터")
    }

    private var filteredProjects: [KnittingProject] {
        guard let selectedStatusFilter else {
            return viewModel.projects
        }

        return viewModel.projects.filter { $0.status == selectedStatusFilter }
    }

    private var syncRetryRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Label("계정 저장 확인이 필요한 프로젝트가 있어요.", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task {
                    await viewModel.retrySync()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRetryingSync)
        }
        .padding(.vertical, 6)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func errorRow(message: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)

            Spacer()

            Button {
                Task {
                    await viewModel.retrySync()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRetryingSync)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            if let errorMessage = viewModel.errorMessage {
                OfflineFirstNoticeView(
                    title: "서버에 연결하지 못했어요.",
                    message: "계정 데이터를 불러오려면 서버 연결이 필요해요. 연결을 확인한 뒤 다시 시도해 주세요.",
                    detail: errorMessage,
                    systemImage: "wifi.exclamationmark"
                ) {
                    Task {
                        await viewModel.retrySync()
                    }
                }
                .padding(.horizontal, 24)
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("아직 등록된 프로젝트가 없어요.")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("첫 뜨개 프로젝트를 추가해 보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                isShowingAddProject = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Color.softAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .warmScreenBackground()
    }
}

#Preview {
    NavigationStack {
        MyKnittingView(repositories: .shared)
    }
}

struct OfflineFirstNoticeView: View {
    let title: String
    let message: String
    let detail: String?
    let systemImage: String
    let retryAction: () -> Void

    init(
        title: String,
        message: String,
        detail: String? = nil,
        systemImage: String,
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.detail = detail
        self.systemImage = systemImage
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.Color.amber)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: retryAction) {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .appCard()
    }
}
