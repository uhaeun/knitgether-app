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
    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy
}
