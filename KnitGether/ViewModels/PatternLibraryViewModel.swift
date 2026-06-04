//
//  PatternLibraryViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

@MainActor
final class PatternLibraryViewModel: ObservableObject {
    @Published private(set) var patterns: [PatternDocument] = []
    @Published private(set) var errorMessage: String?

    private let patternRepository: any PatternRepository

    init(patternRepository: any PatternRepository) {
        self.patternRepository = patternRepository
    }

    func loadPatterns() async {
        do {
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안 창고를 불러오지 못했어요."
        }
    }

    func addPattern(fromFileAt fileURL: URL) async {
        do {
            _ = try await patternRepository.createPattern(fromFileAt: fileURL)
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안을 등록하지 못했어요."
        }
    }

    func deletePattern(_ pattern: PatternDocument) async {
        do {
            try await patternRepository.deletePattern(id: pattern.id)
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안을 삭제하지 못했어요."
        }
    }
}
