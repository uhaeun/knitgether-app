//
//  ProjectRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol ProjectRepository {
    func fetchProjects() async throws -> [KnittingProject]
    func fetchProject(id: UUID) async throws -> KnittingProject?
    func saveProject(_ project: KnittingProject) async throws
    func deleteProject(id: UUID) async throws
    func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter
    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction
    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws
    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession
    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws
    /// 직전 목록 조회가 서버 응답 대신 로컬 캐시로 폴백했는지.
    /// 무통보 폴백을 화면에서 안내하기 위한 신호다(CNT-03 잔여 무통보).
    var isLastListFetchServedFromCache: Bool { get async }
}

extension ProjectRepository {
    var isLastListFetchServedFromCache: Bool {
        get async { false }
    }
}

extension ProjectRepository {
    func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter {
        guard let project = try await fetchProject(id: projectId) else {
            throw APIError.requestFailed(
                statusCode: 404,
                code: "PROJECT_NOT_FOUND",
                message: "Project not found."
            )
        }

        try await saveProject(project.copy(rowCounter: rowCounter))
        return rowCounter
    }

    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction {
        guard let project = try await fetchProject(id: projectId) else {
            throw APIError.requestFailed(
                statusCode: 404,
                code: "PROJECT_NOT_FOUND",
                message: "Project not found."
            )
        }

        let currentInstructions = project.rowCounter.rowInstructions
        let updatedInstructions: [RowInstruction]
        if currentInstructions.contains(where: { $0.id == instruction.id }) {
            updatedInstructions = currentInstructions.map { $0.id == instruction.id ? instruction : $0 }
        } else {
            updatedInstructions = currentInstructions + [instruction]
        }
        let updatedCounter = project.rowCounter.copy(rowInstructions: updatedInstructions)

        try await saveProject(project.copy(rowCounter: updatedCounter))
        return instruction
    }

    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws {
        guard let project = try await fetchProject(id: projectId) else {
            throw APIError.requestFailed(
                statusCode: 404,
                code: "PROJECT_NOT_FOUND",
                message: "Project not found."
            )
        }

        let updatedCounter = project.rowCounter.copy(
            rowInstructions: project.rowCounter.rowInstructions.filter { $0.id != id }
        )
        try await saveProject(project.copy(rowCounter: updatedCounter))
    }

    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
        guard let project = try await fetchProject(id: projectId) else {
            throw APIError.requestFailed(
                statusCode: 404,
                code: "PROJECT_NOT_FOUND",
                message: "Project not found."
            )
        }

        let currentSessions = project.workSessions
        let updatedSessions: [WorkSession]
        if currentSessions.contains(where: { $0.id == session.id }) {
            updatedSessions = currentSessions.map { $0.id == session.id ? session : $0 }
        } else {
            updatedSessions = currentSessions + [session]
        }

        // 세션을 저장할 때 프로젝트의 마지막 작업 시각도 함께 갱신한다.
        // 이게 빠져 있어서 저장 파일의 lastWorkedAt이 계속 nil로 남았고,
        // 목록의 최근 작업 순 정렬과 홈의 이어서 뜨기가 동작하지 않았다 (DEF-17).
        let latestWorkedAt = updatedSessions.compactMap(\.endedAt).max()
        try await saveProject(
            project.copy(
                lastWorkedAt: latestWorkedAt ?? project.lastWorkedAt,
                workSessions: updatedSessions
            )
        )
        return session
    }

    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
        guard let project = try await fetchProject(id: projectId) else {
            throw APIError.requestFailed(
                statusCode: 404,
                code: "PROJECT_NOT_FOUND",
                message: "Project not found."
            )
        }

        try await saveProject(
            project.copy(workSessions: project.workSessions.filter { $0.id != id })
        )
    }
}
