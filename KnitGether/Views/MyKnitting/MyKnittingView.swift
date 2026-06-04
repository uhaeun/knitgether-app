//
//  MyKnittingView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct MyKnittingView: View {
    @StateObject private var viewModel: MyKnittingViewModel
    @State private var isShowingAddProject = false
    @State private var editingProject: KnittingProject?
    @State private var projectPendingDeletion: KnittingProject?
    @State private var isShowingDeleteConfirmation = false

    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: MyKnittingViewModel(projectRepository: repositories.projectRepository)
        )
        projectRepository = repositories.projectRepository
        patternRepository = repositories.patternRepository
        skillRepository = repositories.skillRepository
    }

    var body: some View {
        Group {
            if viewModel.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
        .navigationTitle("My Knitting")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddProject = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddProject) {
            AddProjectView { formData in
                Task {
                    await viewModel.addProject(from: formData)
                }
            }
        }
        .sheet(item: $editingProject) { project in
            EditProjectView(
                project: project,
                onSave: { formData in
                    Task {
                        await viewModel.updateProject(project, with: formData)
                    }
                },
                onDelete: {
                    Task {
                        await viewModel.deleteProject(project)
                    }
                }
            )
        }
        .alert("프로젝트를 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: projectPendingDeletion) { project in
            Button("취소", role: .cancel) {
                projectPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteProject(project)
                    projectPendingDeletion = nil
                }
            }
        } message: { _ in
            Text("삭제한 프로젝트는 복구할 수 없어요.")
        }
        .onAppear {
            Task {
                await viewModel.loadProjects()
            }
        }
    }

    private var projectList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.projects) { project in
                NavigationLink {
                    ProjectWorkspaceView(
                        viewModel: ProjectWorkspaceViewModel(
                            project: project,
                            projectRepository: projectRepository,
                            patternRepository: patternRepository,
                            skillRepository: skillRepository
                        )
                    )
                } label: {
                    ProjectCardView(project: project)
                }
                .buttonStyle(.plain)
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
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
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

            Button {
                isShowingAddProject = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyKnittingView(repositories: .shared)
    }
}
