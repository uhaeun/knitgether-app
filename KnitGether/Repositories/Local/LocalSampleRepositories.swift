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
    private let fileURL: URL
    private let bundledSeedMarkerURL: URL
    private let fileManager: FileManager
    private let fileStore: LocalPatternFileStore
    private var patterns: [PatternDocument]

    init(
        patterns: [PatternDocument]? = nil,
        fileManager: FileManager = .default,
        fileURL: URL? = nil,
        fileStore: LocalPatternFileStore = LocalPatternFileStore()
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        bundledSeedMarkerURL = Self.defaultBundledSeedMarkerURL(fileManager: fileManager)
        self.fileStore = fileStore

        if let patterns {
            self.patterns = patterns
        } else {
            self.patterns = Self.loadPatterns(
                fileURL: self.fileURL,
                fileManager: fileManager
            )
            seedBundledSamplePatternsIfNeeded()
        }
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        patterns
            .filter { $0.deletedAt == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        patterns.first { $0.id == id && $0.deletedAt == nil }
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }

        try persistPatterns()
    }

    func deletePattern(id: UUID) async throws {
        guard let index = patterns.firstIndex(where: { $0.id == id }) else {
            return
        }

        let pattern = patterns[index]
        try fileStore.removeFile(at: pattern.localFilePath)
        patterns.remove(at: index)
        try persistPatterns()
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        let patternId = UUID()
        let storedFile = try fileStore.storeLibraryPatternFile(from: fileURL, patternId: patternId)
        let now = Date()
        let title = fileURL.deletingPathExtension().lastPathComponent

        let pattern = PatternDocument(
            id: patternId,
            ownerId: SampleData.ownerId,
            title: title.isEmpty ? storedFile.fileName : title,
            designer: nil,
            fileName: storedFile.fileName,
            localFilePath: storedFile.relativePath,
            pageCount: nil,
            notes: "",
            createdAt: now,
            updatedAt: now
        )

        try await savePattern(pattern)
        return pattern
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let copyId = UUID()
        let copiedFile: StoredPatternFile?

        if let sourceURL = fileURL(for: pattern) {
            copiedFile = try fileStore.storeProjectPatternFile(
                from: sourceURL,
                projectId: projectId,
                copyId: copyId
            )
        } else {
            copiedFile = nil
        }

        let now = Date()

        return ProjectPatternCopy(
            id: copyId,
            ownerId: pattern.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: pattern.id,
            titleSnapshot: pattern.title,
            designerSnapshot: pattern.designer,
            fileNameSnapshot: copiedFile?.fileName ?? pattern.fileName,
            localCopyPath: copiedFile?.relativePath,
            pageCountSnapshot: pattern.pageCount,
            copiedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let copyId = UUID()
        let storedFile = try fileStore.storeProjectPatternFile(
            from: fileURL,
            projectId: projectId,
            copyId: copyId
        )
        let now = Date()
        let title = fileURL.deletingPathExtension().lastPathComponent

        return ProjectPatternCopy(
            id: copyId,
            ownerId: SampleData.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: nil,
            titleSnapshot: title.isEmpty ? storedFile.fileName : title,
            designerSnapshot: nil,
            fileNameSnapshot: storedFile.fileName,
            localCopyPath: storedFile.relativePath,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        fileStore.fileURL(for: pattern.localFilePath)
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        fileStore.fileURL(for: patternCopy.localCopyPath)
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        try fileStore.loadData(at: patternCopy.drawingDataPath)
    }

    func saveDrawingData(
        _ data: Data,
        for patternCopy: ProjectPatternCopy
    ) async throws -> ProjectPatternCopy {
        let relativePath = try fileStore.storeProjectPatternDrawingData(
            data,
            projectId: patternCopy.projectId,
            copyId: patternCopy.id
        )

        return patternCopy.updatingDrawingDataPath(relativePath)
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        try fileStore.removeFile(at: patternCopy.drawingDataPath)
        return patternCopy.updatingDrawingDataPath(nil)
    }

    private func persistPatterns() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(patterns)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func seedBundledSamplePatternsIfNeeded() {
        guard !fileManager.fileExists(atPath: bundledSeedMarkerURL.path) else {
            return
        }

        var didChangePatterns = false

        for resource in SampleData.bundledPatternResources {
            guard let sourceURL = bundledPatternFileURL(fileName: resource.fileName) else {
                continue
            }

            if let index = patterns.firstIndex(where: { $0.title == resource.title || $0.fileName == resource.fileName }) {
                let existingPattern = patterns[index]

                if let existingFileURL = fileStore.fileURL(for: existingPattern.localFilePath),
                   fileManager.fileExists(atPath: existingFileURL.path) {
                    continue
                }

                do {
                    let storedFile = try fileStore.storeLibraryPatternFile(
                        from: sourceURL,
                        patternId: existingPattern.id
                    )

                    patterns[index] = PatternDocument(
                        id: existingPattern.id,
                        ownerId: existingPattern.ownerId ?? SampleData.ownerId,
                        title: resource.title,
                        designer: existingPattern.designer,
                        fileName: storedFile.fileName,
                        localFilePath: storedFile.relativePath,
                        pageCount: existingPattern.pageCount,
                        notes: existingPattern.notes.isEmpty ? resource.notes : existingPattern.notes,
                        createdAt: existingPattern.createdAt,
                        updatedAt: Date(),
                        deletedAt: existingPattern.deletedAt,
                        syncStatus: existingPattern.syncStatus
                    )
                    didChangePatterns = true
                } catch {
                    continue
                }
            } else {
                do {
                    let patternId = UUID()
                    let storedFile = try fileStore.storeLibraryPatternFile(
                        from: sourceURL,
                        patternId: patternId
                    )

                    let pattern = PatternDocument(
                        id: patternId,
                        ownerId: SampleData.ownerId,
                        title: resource.title,
                        designer: nil,
                        fileName: storedFile.fileName,
                        localFilePath: storedFile.relativePath,
                        pageCount: nil,
                        notes: resource.notes,
                        createdAt: resource.createdAt,
                        updatedAt: resource.updatedAt
                    )

                    patterns.append(pattern)
                    didChangePatterns = true
                } catch {
                    continue
                }
            }
        }

        if didChangePatterns {
            try? persistPatterns()
        }

        markBundledSamplePatternsSeeded()
    }

    private func bundledPatternFileURL(fileName: String) -> URL? {
        let fileURL = URL(fileURLWithPath: fileName)
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        let resourceExtension = fileURL.pathExtension.isEmpty ? nil : fileURL.pathExtension
        let subdirectories: [String?] = [
            "Resources/SamplePatterns",
            "SamplePatterns",
            nil
        ]

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }

    private func markBundledSamplePatternsSeeded() {
        do {
            let directoryURL = bundledSeedMarkerURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try Data().write(to: bundledSeedMarkerURL, options: [.atomic])
        } catch {
        }
    }

    private static func loadPatterns(
        fileURL: URL,
        fileManager: FileManager
    ) -> [PatternDocument] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let samplePatterns = SampleData.patternDocuments
            persistInitialPatterns(samplePatterns, fileURL: fileURL, fileManager: fileManager)
            return samplePatterns
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([PatternDocument].self, from: data)
        } catch {
            return SampleData.patternDocuments
        }
    }

    private static func persistInitialPatterns(
        _ patterns: [PatternDocument],
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(patterns)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("patterns.json")
    }

    private static func defaultBundledSeedMarkerURL(fileManager: FileManager) -> URL {
        defaultFileURL(fileManager: fileManager)
            .deletingLastPathComponent()
            .appendingPathComponent("sample-patterns-v1.seeded")
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
    private let fileURL: URL
    private let fileManager: FileManager
    private var skills: [Skill]
    private let animations: [SkillAnimation]

    init(
        skills: [Skill]? = nil,
        animations: [SkillAnimation] = SampleData.skillAnimations,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.animations = animations

        if let skills {
            self.skills = skills
        } else {
            self.skills = Self.loadSkills(
                fileURL: self.fileURL,
                fileManager: fileManager
            )
        }
    }

    func fetchSkills() async throws -> [Skill] {
        skills
            .filter { $0.deletedAt == nil }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func fetchSkill(id: UUID) async throws -> Skill? {
        skills.first { $0.id == id && $0.deletedAt == nil }
    }

    func saveSkill(_ skill: Skill) async throws {
        if let index = skills.firstIndex(where: { $0.id == skill.id }) {
            skills[index] = skill
        } else {
            skills.append(skill)
        }

        try persistSkills()
    }

    func deleteSkill(id: UUID) async throws {
        skills.removeAll { $0.id == id }
        try persistSkills()
    }

    func fetchSkillAnimations() async throws -> [SkillAnimation] {
        animations.filter { $0.deletedAt == nil }
    }

    private func persistSkills() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(skills)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadSkills(
        fileURL: URL,
        fileManager: FileManager
    ) -> [Skill] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let sampleSkills = SampleData.skills
            persistInitialSkills(sampleSkills, fileURL: fileURL, fileManager: fileManager)
            return sampleSkills
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Skill].self, from: data)
        } catch {
            return SampleData.skills
        }
    }

    private static func persistInitialSkills(
        _ skills: [Skill],
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(skills)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("skills.json")
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
