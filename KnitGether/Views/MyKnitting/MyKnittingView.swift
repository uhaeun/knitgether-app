//
//  MyKnittingView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct MyKnittingView: View {
    @StateObject private var viewModel: MyKnittingViewModel
    private let projectRepository: any ProjectRepository
    private let skillRepository: any SkillRepository

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: MyKnittingViewModel(projectRepository: repositories.projectRepository)
        )
        projectRepository = repositories.projectRepository
        skillRepository = repositories.skillRepository
    }

    var body: some View {
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
                            skillRepository: skillRepository
                        )
                    )
                } label: {
                    ProjectCardView(project: project)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationTitle("My Knitting")
        .task {
            await viewModel.loadProjects()
        }
    }
}

#Preview {
    NavigationStack {
        MyKnittingView(repositories: .shared)
    }
}
