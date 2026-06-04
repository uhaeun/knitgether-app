//
//  AppRepositoryContainer.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

final class AppRepositoryContainer {
    static let shared = AppRepositoryContainer()

    let projectRepository: any ProjectRepository
    let patternRepository: any PatternRepository
    let libraryRepository: any LibraryRepository
    let skillRepository: any SkillRepository
    let profileRepository: any ProfileRepository

    init(
        projectRepository: any ProjectRepository = LocalProjectRepository(),
        patternRepository: any PatternRepository = LocalPatternRepository(),
        libraryRepository: any LibraryRepository = LocalLibraryRepository(),
        skillRepository: any SkillRepository = LocalSkillRepository(),
        profileRepository: any ProfileRepository = LocalProfileRepository()
    ) {
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.profileRepository = profileRepository
    }
}
