//
//  ProjectWorkspaceViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

enum PatternInteractionMode: String, CaseIterable, Identifiable {
    case viewer = "Viewer"
    case drawing = "Drawing"

    var id: String {
        rawValue
    }
}

@MainActor
final class ProjectWorkspaceViewModel: ObservableObject {
    @Published private(set) var project: KnittingProject
    @Published var interactionMode: PatternInteractionMode = .viewer
    @Published private(set) var currentRow: Int
    @Published private(set) var relatedSkills: [Skill] = []
    @Published private(set) var isTrackingTime = false
    @Published private(set) var errorMessage: String?

    private let projectRepository: any ProjectRepository
    private let skillRepository: any SkillRepository

    init(
        project: KnittingProject,
        projectRepository: any ProjectRepository,
        skillRepository: any SkillRepository
    ) {
        self.project = project
        self.projectRepository = projectRepository
        self.skillRepository = skillRepository
        currentRow = project.rowCounter.currentRow
    }

    func loadRelatedSkills() async {
        do {
            let skills = try await skillRepository.fetchSkills()
            relatedSkills = skills.filter { project.relatedSkillIds.contains($0.id) }
            errorMessage = nil
        } catch {
            errorMessage = "Could not load related skills."
        }
    }

    func decrementRow() {
        currentRow = max(0, currentRow - 1)
    }

    func incrementRow() {
        currentRow += 1
    }

    func toggleWorkTimer() {
        isTrackingTime.toggle()
    }

    func saveCurrentProjectSnapshot() async {
        do {
            try await projectRepository.saveProject(project)
            errorMessage = nil
        } catch {
            errorMessage = "Could not save project."
        }
    }
}
