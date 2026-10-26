//
//  PatternRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol PatternRepository {
    func fetchPatterns() async throws -> [PatternDocument]
    func fetchPattern(id: UUID) async throws -> PatternDocument?
    func savePattern(_ pattern: PatternDocument) async throws
    func deletePattern(id: UUID) async throws
    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument
    func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument
    func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument
    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy
    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy
    func fileURL(for pattern: PatternDocument) -> URL?
    func fileURL(for patternCopy: ProjectPatternCopy) -> URL?
    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data?
    func saveDrawingChange(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectDrawingChange
    func deleteDrawingChange(for patternCopy: ProjectPatternCopy) async throws -> ProjectDrawingChange
    func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy
    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy
}

/// Whether a drawing mutation already committed its project metadata to the server.
struct ProjectDrawingChange {
    let patternCopy: ProjectPatternCopy
    let requiresProjectSave: Bool
}

extension PatternRepository {
    func saveDrawingChange(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectDrawingChange {
        ProjectDrawingChange(patternCopy: try await saveDrawingData(data, for: patternCopy), requiresProjectSave: true)
    }

    func deleteDrawingChange(for patternCopy: ProjectPatternCopy) async throws -> ProjectDrawingChange {
        ProjectDrawingChange(patternCopy: try await deleteDrawingData(for: patternCopy), requiresProjectSave: true)
    }
}
