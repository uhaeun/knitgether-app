//
//  LocalSampleRepositories.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

final class LocalProjectRepository: ProjectRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private var projects: [KnittingProject]

    init(
        projects: [KnittingProject]? = nil,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)

        if let projects {
            self.projects = projects
        } else {
            self.projects = Self.loadProjects(
                fileURL: self.fileURL,
                fileManager: fileManager
            )
        }
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

        try persistProjects()
    }

    func deleteProject(id: UUID) async throws {
        projects.removeAll { $0.id == id }
        try persistProjects()
    }

    private func persistProjects() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(projects)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadProjects(
        fileURL: URL,
        fileManager: FileManager
    ) -> [KnittingProject] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let sampleProjects = SampleData.projects
            persistInitialProjects(sampleProjects, fileURL: fileURL, fileManager: fileManager)
            return sampleProjects
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([KnittingProject].self, from: data)
        } catch {
            return SampleData.projects
        }
    }

    private static func persistInitialProjects(
        _ projects: [KnittingProject],
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(projects)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("projects.json")
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
