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
    @Published private(set) var availableYarns: [Yarn] = []
    @Published private(set) var availableNeedles: [Needle] = []
    @Published private(set) var availablePatterns: [PatternDocument] = []
    @Published private(set) var isRetryingSync = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var statusMessage: String?

    private let projectRepository: any ProjectRepository
    private let patternRepository: (any PatternRepository)?
    private let libraryRepository: (any LibraryRepository)?

    init(
        projectRepository: any ProjectRepository,
        patternRepository: (any PatternRepository)? = nil,
        libraryRepository: (any LibraryRepository)? = nil
    ) {
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
    }

    var hasProjectsNeedingSync: Bool {
        projects.contains { $0.syncStatus.needsSync }
    }

    func loadProjects() async {
        do {
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트를 불러오지 못했어요."
            statusMessage = nil
        }
    }

    func reloadAfterAccountChange() async {
        projects = []
        availablePatterns = []
        availableYarns = []
        availableNeedles = []
        errorMessage = nil
        statusMessage = nil
        await loadProjects()
        await loadProjectPatterns()
        await loadProjectMaterials()
    }

    func loadProjectPatterns() async {
        guard let patternRepository else {
            return
        }

        do {
            availablePatterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트 도안 목록을 불러오지 못했어요."
            statusMessage = nil
        }
    }

    func loadProjectMaterials() async {
        guard let libraryRepository else {
            return
        }

        do {
            availableYarns = try await libraryRepository.fetchYarns()
            availableNeedles = try await libraryRepository.fetchNeedles()
            errorMessage = nil
        } catch {
            errorMessage = "프로젝트 재료를 불러오지 못했어요."
            statusMessage = nil
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadProjects()
        isRetryingSync = false
    }

    @discardableResult
    func addProject(from formData: ProjectFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            statusMessage = nil
            return false
        }

        do {
            let project = makeProject(from: formData)
            try await projectRepository.saveProject(project)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
            statusMessage = "프로젝트를 추가했어요."
            return true
        } catch {
            errorMessage = "프로젝트를 추가하지 못했어요."
            statusMessage = nil
            return false
        }
    }

    @discardableResult
    func updateProject(_ project: KnittingProject, with formData: ProjectFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "프로젝트 이름을 입력해 주세요."
            statusMessage = nil
            return false
        }

        do {
            let updatedProject = update(project, with: formData)
            try await projectRepository.saveProject(updatedProject)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
            statusMessage = "프로젝트를 수정했어요."
            return true
        } catch {
            errorMessage = "프로젝트를 수정하지 못했어요."
            statusMessage = nil
            return false
        }
    }

    @discardableResult
    func deleteProject(_ project: KnittingProject) async -> Bool {
        do {
            try await projectRepository.deleteProject(id: project.id)
            projects = try await projectRepository.fetchProjects()
            errorMessage = nil
            statusMessage = "프로젝트를 삭제했어요."
            return true
        } catch {
            errorMessage = "프로젝트를 삭제하지 못했어요."
            statusMessage = nil
            return false
        }
    }

    func clearStatusMessage() {
        statusMessage = nil
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
            targetDate: formData.effectiveTargetDate,
            finishedAt: formData.effectiveFinishedAt,
            lastWorkedAt: nil,
            patternCopy: patternCopy,
            yarnId: formData.yarnId,
            yarnNameSnapshot: formData.trimmedYarnNameSnapshot,
            yarnBrandSnapshot: formData.trimmedYarnBrandSnapshot,
            yarnColorwaySnapshot: formData.trimmedYarnColorwaySnapshot,
            yarnWeightSnapshot: formData.trimmedYarnWeightSnapshot,
            needleId: formData.needleId,
            needleNameSnapshot: formData.trimmedNeedleNameSnapshot,
            needleTypeSnapshot: formData.trimmedNeedleTypeSnapshot,
            needleSizeSnapshot: formData.trimmedNeedleSizeSnapshot,
            needleLengthSnapshot: formData.trimmedNeedleLengthSnapshot,
            workspaceDisplayMode: .patternAndCounter,
            workspaceSheetPosition: .medium,
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
            targetDate: formData.effectiveTargetDate,
            finishedAt: formData.effectiveFinishedAt,
            lastWorkedAt: project.lastWorkedAt,
            patternCopy: project.patternCopy,
            yarnId: formData.yarnId,
            yarnNameSnapshot: formData.trimmedYarnNameSnapshot,
            yarnBrandSnapshot: formData.trimmedYarnBrandSnapshot,
            yarnColorwaySnapshot: formData.trimmedYarnColorwaySnapshot,
            yarnWeightSnapshot: formData.trimmedYarnWeightSnapshot,
            needleId: formData.needleId,
            needleNameSnapshot: formData.trimmedNeedleNameSnapshot,
            needleTypeSnapshot: formData.trimmedNeedleTypeSnapshot,
            needleSizeSnapshot: formData.trimmedNeedleSizeSnapshot,
            needleLengthSnapshot: formData.trimmedNeedleLengthSnapshot,
            workspaceDisplayMode: project.workspaceDisplayMode,
            workspaceSheetPosition: project.workspaceSheetPosition,
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
            sourcePatternDocumentId: formData.patternDocumentId,
            titleSnapshot: patternName,
            designerSnapshot: formData.trimmedPatternDesignerSnapshot,
            fileNameSnapshot: formData.trimmedPatternFileNameSnapshot,
            localCopyPath: nil,
            pageCountSnapshot: formData.patternPageCountSnapshot,
            copiedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
}
