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
    @Published private(set) var sheetPosition: ProjectWorkspaceSheetPosition
    @Published var interactionMode: PatternInteractionMode = .viewer
    @Published var memoText: String
    @Published private(set) var currentRow: Int
    @Published private(set) var currentSessionElapsed: TimeInterval = 0
    @Published private(set) var relatedSkills: [Skill] = []
    @Published private(set) var availablePatterns: [PatternDocument] = []
    @Published private(set) var attachedPatternFileURL: URL?
    @Published var drawingData: Data?
    @Published private(set) var isTrackingTime = false
    @Published private(set) var errorMessage: String?

    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository
    private var sessionStartedAt: Date?
    private var isDeleted = false

    init(
        project: KnittingProject,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        skillRepository: any SkillRepository
    ) {
        self.project = project
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.skillRepository = skillRepository
        sheetPosition = Self.resolvedSheetPosition(for: project)
        memoText = project.memo
        currentRow = project.rowCounter.currentRow
        attachedPatternFileURL = project.patternCopy.flatMap { patternRepository.fileURL(for: $0) }
    }

    var hasUnsavedMemoChanges: Bool {
        memoText != project.memo
    }

    func loadRelatedSkills() async {
        do {
            let skills = try await skillRepository.fetchSkills()
            let sourceText = await relatedSkillSourceText()
            let explicitSkillIds = Set(project.relatedSkillIds)

            relatedSkills = skills.filter { skill in
                explicitSkillIds.contains(skill.id)
                    || Self.containsAbbreviation(skill.abbreviation, in: sourceText)
            }
            errorMessage = nil
        } catch {
            errorMessage = "관련 스킬을 불러오지 못했어요."
        }
    }

    func loadAvailablePatterns() async {
        do {
            availablePatterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안 창고를 불러오지 못했어요."
        }
    }

    func loadDrawingData() async {
        guard let patternCopy = project.patternCopy else {
            drawingData = nil
            return
        }

        do {
            drawingData = try await patternRepository.drawingData(for: patternCopy)
            errorMessage = nil
        } catch {
            errorMessage = "그리기 데이터를 불러오지 못했어요."
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

    func updateSheetPosition(_ position: ProjectWorkspaceSheetPosition) async {
        guard position != sheetPosition else {
            return
        }

        sheetPosition = position
        let updatedProject = project.copy(workspaceSheetPosition: position)
        await persist(updatedProject, errorMessage: "작업 화면 위치를 저장하지 못했어요.")
    }

    func saveDrawingData(_ data: Data) async {
        guard let patternCopy = project.patternCopy else {
            errorMessage = "도안을 추가한 뒤 그리기를 사용할 수 있어요."
            return
        }

        do {
            let updatedPatternCopy = try await patternRepository.saveDrawingData(data, for: patternCopy)
            let updatedProject = project.copy(patternCopy: updatedPatternCopy)
            try await projectRepository.saveProject(updatedProject)
            project = updatedProject
            drawingData = data
            refreshAttachedPatternFileURL()
            errorMessage = nil
        } catch {
            errorMessage = "그리기를 저장하지 못했어요."
        }
    }

    func clearDrawingData() async {
        guard let patternCopy = project.patternCopy else {
            drawingData = nil
            return
        }

        do {
            let updatedPatternCopy = try await patternRepository.deleteDrawingData(for: patternCopy)
            let updatedProject = project.copy(patternCopy: updatedPatternCopy)
            try await projectRepository.saveProject(updatedProject)
            project = updatedProject
            drawingData = nil
            refreshAttachedPatternFileURL()
            errorMessage = nil
        } catch {
            errorMessage = "그리기를 삭제하지 못했어요."
        }
    }

    func saveMemo() async {
        let updatedProject = project.updatingMemo(to: memoText)
        await persist(updatedProject, errorMessage: "작업 메모를 저장하지 못했어요.")
        await loadRelatedSkills()
    }

    func attachNewPattern(fromFileAt fileURL: URL) async {
        do {
            let patternCopy = try await patternRepository.createProjectPatternCopy(
                fromFileAt: fileURL,
                forProjectId: project.id
            )
            let updatedProject = project.copy(patternCopy: patternCopy)
            await persist(updatedProject, errorMessage: "도안을 프로젝트에 추가하지 못했어요.")
            drawingData = nil
            await loadRelatedSkills()
        } catch {
            errorMessage = "도안을 프로젝트에 추가하지 못했어요."
        }
    }

    func attachPatternFromLibrary(_ pattern: PatternDocument) async {
        do {
            let patternCopy = try await patternRepository.importPattern(pattern, forProjectId: project.id)
            let updatedProject = project.copy(patternCopy: patternCopy)
            await persist(updatedProject, errorMessage: "도안을 Library에서 가져오지 못했어요.")
            drawingData = nil
            await loadRelatedSkills()
        } catch {
            errorMessage = "도안을 Library에서 가져오지 못했어요."
        }
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
            sheetPosition = Self.resolvedSheetPosition(for: updatedProject)
            memoText = updatedProject.memo
            currentRow = updatedProject.rowCounter.currentRow
            refreshAttachedPatternFileURL()
            errorMessage = nil
            await loadRelatedSkills()
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
            sheetPosition = Self.resolvedSheetPosition(for: updatedProject)
            memoText = updatedProject.memo
            currentRow = updatedProject.rowCounter.currentRow
            refreshAttachedPatternFileURL()
            self.errorMessage = nil
        } catch {
            self.errorMessage = errorMessage
        }
    }

    private func refreshAttachedPatternFileURL() {
        attachedPatternFileURL = project.patternCopy.flatMap { patternRepository.fileURL(for: $0) }
    }

    private static func resolvedSheetPosition(for project: KnittingProject) -> ProjectWorkspaceSheetPosition {
        project.workspaceSheetPosition ?? ProjectWorkspaceSheetPosition(displayMode: project.workspaceDisplayMode)
    }

    private func relatedSkillSourceText() async -> String {
        var components: [String] = [
            project.name,
            project.memo,
            memoText
        ]

        components.append(contentsOf: project.workSessions.compactMap(\.memo))

        if let patternCopy = project.patternCopy {
            components.append(patternCopy.titleSnapshot)

            if let fileName = patternCopy.fileNameSnapshot {
                components.append(fileName)
            }

            if let sourcePatternDocumentId = patternCopy.sourcePatternDocumentId,
               let sourcePattern = try? await patternRepository.fetchPattern(id: sourcePatternDocumentId) {
                components.append(sourcePattern.title)
                components.append(sourcePattern.notes)
            }
        }

        return components.joined(separator: " ")
    }

    private static func containsAbbreviation(_ abbreviation: String, in text: String) -> Bool {
        let normalizedAbbreviation = abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !normalizedAbbreviation.isEmpty else {
            return false
        }

        let tokens = text
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return tokens.contains { token in
            if token == normalizedAbbreviation {
                return true
            }

            guard token.hasPrefix(normalizedAbbreviation) else {
                return false
            }

            let suffix = token.dropFirst(normalizedAbbreviation.count)
            return !suffix.isEmpty && suffix.allSatisfy(\.isNumber)
        }
    }
}
