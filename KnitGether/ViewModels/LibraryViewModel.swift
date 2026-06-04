//
//  LibraryViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var patterns: [PatternDocument] = []
    @Published private(set) var yarns: [Yarn] = []
    @Published private(set) var needles: [Needle] = []
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var errorMessage: String?

    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository

    init(
        patternRepository: any PatternRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository
    ) {
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
    }

    func loadLibrary() async {
        do {
            patterns = try await patternRepository.fetchPatterns()
            yarns = try await libraryRepository.fetchYarns()
            needles = try await libraryRepository.fetchNeedles()
            skills = try await skillRepository.fetchSkills()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load library."
        }
    }
}
