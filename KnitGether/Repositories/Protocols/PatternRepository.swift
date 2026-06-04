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
    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy
    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy
    func fileURL(for pattern: PatternDocument) -> URL?
    func fileURL(for patternCopy: ProjectPatternCopy) -> URL?
    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data?
    func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy
    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy
}
