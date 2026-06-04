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
            errorMessage = "프로젝트를 불러오지 못했어요."
        }
    }

    func addProject(from formData: ProjectFormData) async {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            return
        }

        do {
            let project = makeProject(from: formData)
            try await projectRepository.saveProject(project)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트를 추가하지 못했어요."
        }
    }

    func updateProject(_ project: KnittingProject, with formData: ProjectFormData) async {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            return
        }

        do {
            let updatedProject = update(project, with: formData)
            try await projectRepository.saveProject(updatedProject)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트를 수정하지 못했어요."
        }
    }

    func deleteProject(_ project: KnittingProject) async {
        do {
            try await projectRepository.deleteProject(id: project.id)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트를 삭제하지 못했어요."
        }
    }

    private func makeProject(from formData: ProjectFormData) -> KnittingProject {
        let now = Date()
        let projectId = UUID()
        let patternCopy = makePatternCopy(
            from: formData,
            projectId: projectId,
            now: now
        )

        return KnittingProject(
            id: projectId,
            ownerId: SampleData.ownerId,
            name: formData.trimmedName,
            status: formData.status,
            isFavorite: formData.isFavorite,
            memo: formData.trimmedMemo,
            startDate: formData.startDate,
            lastWorkedAt: nil,
            patternCopy: patternCopy,
            rowCounter: RowCounter(
                ownerId: SampleData.ownerId,
                projectId: projectId,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now
            ),
            workSessions: [],
            relatedSkillIds: [],
            createdAt: now,
            updatedAt: now
        )
    }

    private func update(
        _ project: KnittingProject,
        with formData: ProjectFormData
    ) -> KnittingProject {
        KnittingProject(
            id: project.id,
            ownerId: project.ownerId,
            name: formData.trimmedName,
            status: formData.status,
            isFavorite: formData.isFavorite,
            memo: formData.trimmedMemo,
            startDate: formData.startDate,
            lastWorkedAt: project.lastWorkedAt,
            patternCopy: project.patternCopy,
            rowCounter: project.rowCounter,
            workSessions: project.workSessions,
            relatedSkillIds: project.relatedSkillIds,
            createdAt: project.createdAt,
            updatedAt: Date(),
            deletedAt: project.deletedAt,
            syncStatus: project.syncStatus
        )
    }

    private func makePatternCopy(
        from formData: ProjectFormData,
        projectId: UUID,
        now: Date
    ) -> ProjectPatternCopy? {
        let patternName = formData.trimmedPatternName

        guard !patternName.isEmpty else {
            return nil
        }

        return ProjectPatternCopy(
            ownerId: SampleData.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: nil,
            titleSnapshot: patternName,
            designerSnapshot: nil,
            fileNameSnapshot: nil,
            localCopyPath: nil,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
}
