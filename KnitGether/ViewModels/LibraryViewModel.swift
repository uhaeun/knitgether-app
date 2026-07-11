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
    @Published private(set) var tools: [ToolItem] = []
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var errorMessage: String?

    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository

    var isEmpty: Bool {
        patterns.isEmpty && yarns.isEmpty && needles.isEmpty && tools.isEmpty && skills.isEmpty
    }

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
            tools = try await libraryRepository.fetchTools()
            skills = try await skillRepository.fetchSkills()
            errorMessage = nil
        } catch {
            errorMessage = "Library를 불러오지 못했어요."
        }
    }

    func reloadAfterAccountChange() async {
        patterns = []
        yarns = []
        needles = []
        tools = []
        skills = []
        errorMessage = nil
        await loadLibrary()
    }
}
