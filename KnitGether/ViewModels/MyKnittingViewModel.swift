//
//  MyKnittingViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

@MainActor
final class MyKnittingViewModel: ObservableObject {
    @Published private(set) var projects: [KnittingProject] = []
    @Published private(set) var errorMessage: String?

    private let projectRepository: any ProjectRepository

    init(projectRepository: any ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func loadProjects() async {
        do {
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load projects."
        }
    }
}
