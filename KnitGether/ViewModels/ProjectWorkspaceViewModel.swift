//
//  ProjectWorkspaceViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

enum PatternInteractionMode: String, CaseIterable, Identifiable {
    case viewer = "뷰어 모드"
    case drawing = "그리기 모드"

    var id: String {
        rawValue
    }
}

@MainActor
final class ProjectWorkspaceViewModel: ObservableObject {
    @Published private(set) var project: KnittingProject
    @Published var interactionMode: PatternInteractionMode = .viewer
    @Published var memoText: String
    @Published private(set) var currentRow: Int
    @Published private(set) var currentSessionElapsed: TimeInterval = 0
    @Published private(set) var relatedSkills: [Skill] = []
    @Published private(set) var isTrackingTime = false
    @Published private(set) var errorMessage: String?

    private let projectRepository: any ProjectRepository
    private let skillRepository: any SkillRepository
    private var sessionStartedAt: Date?
    private var isDeleted = false

    init(
        project: KnittingProject,
        projectRepository: any ProjectRepository,
        skillRepository: any SkillRepository
    ) {
        self.project = project
        self.projectRepository = projectRepository
        self.skillRepository = skillRepository
        memoText = project.memo
        currentRow = project.rowCounter.currentRow
    }

    var hasUnsavedMemoChanges: Bool {
        memoText != project.memo
    }

    func loadRelatedSkills() async {
        do {
            let skills = try await skillRepository.fetchSkills()
            relatedSkills = skills.filter { project.relatedSkillIds.contains($0.id) }
            errorMessage = nil
        } catch {
            errorMessage = "관련 스킬을 불러오지 못했어요."
        }
    }

    func startWorkSession() {
        guard sessionStartedAt == nil, !isDeleted else {
            return
        }

        sessionStartedAt = Date()
        currentSessionElapsed = 0
        isTrackingTime = true
    }

    func refreshCurrentSessionElapsed() {
        guard let sessionStartedAt else {
            return
        }

        currentSessionElapsed = Date().timeIntervalSince(sessionStartedAt)
    }

    func finishWorkSession() async {
        guard let sessionStartedAt, !isDeleted else {
            return
        }

        let endedAt = Date()
        currentSessionElapsed = endedAt.timeIntervalSince(sessionStartedAt)
        self.sessionStartedAt = nil
        isTrackingTime = false

        guard currentSessionElapsed > 0 else {
            return
        }

        let updatedProject = project.recordingWorkSession(
            startedAt: sessionStartedAt,
            endedAt: endedAt
        )

        await persist(updatedProject, errorMessage: "작업 시간을 저장하지 못했어요.")
    }

    func decrementRow() async {
        await updateRow(to: max(0, currentRow - 1))
    }

    func incrementRow() async {
        await updateRow(to: currentRow + 1)
    }

    func saveMemo() async {
        let updatedProject = project.updatingMemo(to: memoText)
        await persist(updatedProject, errorMessage: "작업 메모를 저장하지 못했어요.")
    }

    func updateProject(with formData: ProjectFormData) async {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            return
        }

        let updatedProject = project.copy(
            name: formData.trimmedName,
            status: formData.status,
            isFavorite: formData.isFavorite,
            memo: formData.trimmedMemo,
            startDate: formData.startDate
        )

        do {
            try await projectRepository.saveProject(updatedProject)
            project = updatedProject
            memoText = updatedProject.memo
            currentRow = updatedProject.rowCounter.currentRow
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트를 수정하지 못했어요."
        }
    }

    func deleteProject() async -> Bool {
        do {
            try await projectRepository.deleteProject(id: project.id)
            isDeleted = true
            sessionStartedAt = nil
            isTrackingTime = false
            errorMessage = nil
            return true
        } catch {
            errorMessage = "프로젝트를 삭제하지 못했어요."
            return false
        }
    }

    private func updateRow(to row: Int) async {
        guard row != currentRow else {
            return
        }

        let updatedProject = project.updatingRow(to: row)
        await persist(updatedProject, errorMessage: "단수를 저장하지 못했어요.")
    }

    private func persist(_ updatedProject: KnittingProject, errorMessage: String) async {
        do {
            try await projectRepository.saveProject(updatedProject)
            project = updatedProject
            memoText = updatedProject.memo
            currentRow = updatedProject.rowCounter.currentRow
            self.errorMessage = nil
        } catch {
            self.errorMessage = errorMessage
        }
    }
}
