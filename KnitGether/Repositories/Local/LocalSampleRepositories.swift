//
//  LocalSampleRepositories.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

final class LocalProjectRepository: ProjectRepository {
    private var projects: [KnittingProject]

    init(projects: [KnittingProject] = SampleData.projects) {
        self.projects = projects
    }

    func fetchProjects() async throws -> [KnittingProject] {
        projects.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite && !second.isFavorite
            }

            return (first.lastWorkedAt ?? first.startDate) > (second.lastWorkedAt ?? second.startDate)
        }
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        projects.first { $0.id == id }
    }

    func saveProject(_ project: KnittingProject) async throws {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
    }
}

final class LocalPatternRepository: PatternRepository {
    private var patterns: [PatternDocument]

    init(patterns: [PatternDocument] = SampleData.patternDocuments) {
        self.patterns = patterns
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        patterns.filter { $0.deletedAt == nil }
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        patterns.first { $0.id == id && $0.deletedAt == nil }
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        ProjectPatternCopy(
            ownerId: pattern.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: pattern.id,
            titleSnapshot: pattern.title,
            designerSnapshot: pattern.designer,
            fileNameSnapshot: pattern.fileName,
            localCopyPath: nil,
            pageCountSnapshot: pattern.pageCount,
            copiedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

final class LocalLibraryRepository: LibraryRepository {
    private let yarns: [Yarn]
    private let needles: [Needle]

    init(
        yarns: [Yarn] = SampleData.yarns,
        needles: [Needle] = SampleData.needles
    ) {
        self.yarns = yarns
        self.needles = needles
    }

    func fetchYarns() async throws -> [Yarn] {
        yarns.filter { $0.deletedAt == nil }
    }

    func fetchNeedles() async throws -> [Needle] {
        needles.filter { $0.deletedAt == nil }
    }
}

final class LocalSkillRepository: SkillRepository {
    private let skills: [Skill]
    private let animations: [SkillAnimation]

    init(
        skills: [Skill] = SampleData.skills,
        animations: [SkillAnimation] = SampleData.skillAnimations
    ) {
        self.skills = skills
        self.animations = animations
    }

    func fetchSkills() async throws -> [Skill] {
        skills.filter { $0.deletedAt == nil }
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        animations.filter { $0.deletedAt == nil }
    }
}

final class LocalProfileRepository: ProfileRepository {
    private let profile: UserProfile

    init(profile: UserProfile = SampleData.profile) {
        self.profile = profile
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        profile
    }
}
