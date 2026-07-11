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
        seedSamples: Bool = true,
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
                fileManager: fileManager,
                seedSamples: seedSamples
            )
        }
    }

    func fetchProjects() async throws -> [KnittingProject] {
        projects.filter { $0.deletedAt == nil }.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite && !second.isFavorite
            }

            return (first.lastWorkedAt ?? first.startDate) > (second.lastWorkedAt ?? second.startDate)
        }
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        projects.first { $0.id == id && $0.deletedAt == nil }
    }

    func saveProject(_ project: KnittingProject) async throws {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }

        try persistProjects()
    }

    func makeRollbackSnapshot() async -> [KnittingProject] {
        projects
    }

    func restoreRollbackSnapshot(_ snapshot: [KnittingProject]) async throws {
        projects = snapshot
        try persistProjects()
    }

    func deleteProject(id: UUID) async throws {
        guard let index = projects.firstIndex(where: { $0.id == id }) else {
            return
        }

        projects[index] = projects[index].copy(
            updatedAt: Date(),
            deletedAt: Date(),
            syncStatus: .pendingDelete
        )
        try persistProjects()
    }

    func cacheSyncedProjects(_ remoteProjects: [KnittingProject]) async throws {
        for remoteProject in remoteProjects {
            let syncedProject = remoteProject.copy(syncStatus: .synced)

            if let index = projects.firstIndex(where: { $0.id == remoteProject.id }) {
                guard !projects[index].syncStatus.needsUpload else {
                    continue
                }

                projects[index] = syncedProject
            } else {
                projects.append(syncedProject)
            }
        }

        try persistProjects()
    }

    func pendingProjectsForSync() async -> [KnittingProject] {
        projects.filter { $0.syncStatus.needsUpload }
    }

    func markProjectSynced(_ project: KnittingProject) async throws {
        try await saveProject(project.copy(syncStatus: .synced))
    }

    func removeProjectTombstone(id: UUID) async throws {
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
        fileManager: FileManager,
        seedSamples: Bool
    ) -> [KnittingProject] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            guard seedSamples else {
                return []
            }

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
            return seedSamples ? SampleData.projects : []
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
        seedSamples: Bool = true,
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
                fileManager: fileManager,
                seedSamples: seedSamples
            )
            if seedSamples {
                seedBundledSamplePatternsIfNeeded()
            }
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

    func makeRollbackSnapshot() async -> [PatternDocument] {
        patterns
    }

    func restoreRollbackSnapshot(_ snapshot: [PatternDocument]) async throws {
        patterns = snapshot
        try persistPatterns()
    }

    func deletePattern(id: UUID) async throws {
        guard let index = patterns.firstIndex(where: { $0.id == id }) else {
            return
        }

        let pattern = patterns[index]
        if pattern.syncStatus == .localOnly {
            try fileStore.removeFile(at: pattern.localFilePath)
            patterns.remove(at: index)
        } else {
            let now = Date()
            patterns[index] = PatternDocument(
                id: pattern.id,
                ownerId: pattern.ownerId,
                title: pattern.title,
                designer: pattern.designer,
                fileName: pattern.fileName,
                localFilePath: pattern.localFilePath,
                pageCount: pattern.pageCount,
                notes: pattern.notes,
                createdAt: pattern.createdAt,
                updatedAt: now,
                deletedAt: now,
                syncStatus: .pendingDelete
            )
        }

        try persistPatterns()
    }

    func cacheSyncedPatterns(_ remotePatterns: [PatternDocument]) async throws {
        for remotePattern in remotePatterns {
            if let index = patterns.firstIndex(where: { $0.id == remotePattern.id }) {
                guard !patterns[index].syncStatus.needsUpload else {
                    continue
                }

                patterns[index] = Self.syncedPattern(
                    from: remotePattern,
                    preservingLocalPathFrom: patterns[index]
                )
            } else {
                patterns.append(
                    Self.syncedPattern(from: remotePattern, preservingLocalPathFrom: nil)
                )
            }
        }

        try persistPatterns()
    }

    func pendingPatternsForSync() async -> [PatternDocument] {
        patterns.filter { $0.syncStatus.needsUpload }
    }

    func markPatternSynced(_ pattern: PatternDocument) async throws {
        let existingPattern = patterns.first { $0.id == pattern.id }
        try await savePattern(
            Self.syncedPattern(
                from: pattern,
                preservingLocalPathFrom: existingPattern
            )
        )
    }

    func removePatternTombstone(id: UUID) async throws {
        if let pattern = patterns.first(where: { $0.id == id }) {
            try fileStore.removeFile(at: pattern.localFilePath)
        }

        patterns.removeAll { $0.id == id }
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

    private static func syncedPattern(
        from pattern: PatternDocument,
        preservingLocalPathFrom existingPattern: PatternDocument?
    ) -> PatternDocument {
        PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId ?? existingPattern?.ownerId,
            title: pattern.title,
            designer: pattern.designer,
            fileName: pattern.fileName ?? existingPattern?.fileName,
            localFilePath: pattern.localFilePath ?? existingPattern?.localFilePath,
            pageCount: pattern.pageCount,
            notes: pattern.notes,
            createdAt: pattern.createdAt,
            updatedAt: pattern.updatedAt,
            deletedAt: nil,
            syncStatus: .synced
        )
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
        fileManager: FileManager,
        seedSamples: Bool
    ) -> [PatternDocument] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            guard seedSamples else {
                return []
            }

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
            return seedSamples ? SampleData.patternDocuments : []
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

struct LocalLibraryRollbackSnapshot {
    let yarns: [Yarn]
    let needles: [Needle]
    let yarnUsages: [ProjectYarnUsage]
    let tools: [ToolItem]
    let projectToolLinks: [ProjectToolLink]
}

final class LocalLibraryRepository: LibraryRepository {
    private struct LibraryCache: Codable {
        let yarns: [Yarn]
        let needles: [Needle]
        let yarnUsages: [ProjectYarnUsage]
        let tools: [ToolItem]
        let projectToolLinks: [ProjectToolLink]

        init(
            yarns: [Yarn],
            needles: [Needle],
            yarnUsages: [ProjectYarnUsage],
            tools: [ToolItem] = [],
            projectToolLinks: [ProjectToolLink] = []
        ) {
            self.yarns = yarns
            self.needles = needles
            self.yarnUsages = yarnUsages
            self.tools = tools
            self.projectToolLinks = projectToolLinks
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            yarns = try container.decodeIfPresent([Yarn].self, forKey: .yarns) ?? []
            needles = try container.decodeIfPresent([Needle].self, forKey: .needles) ?? []
            yarnUsages = try container.decodeIfPresent([ProjectYarnUsage].self, forKey: .yarnUsages) ?? []
            tools = try container.decodeIfPresent([ToolItem].self, forKey: .tools) ?? []
            projectToolLinks = try container.decodeIfPresent([ProjectToolLink].self, forKey: .projectToolLinks) ?? []
        }
    }

    private let fileURL: URL?
    private let fileManager: FileManager
    private let shouldPersist: Bool
    private var yarns: [Yarn]
    private var needles: [Needle]
    private var yarnUsages: [ProjectYarnUsage]
    private var tools: [ToolItem]
    private var projectToolLinks: [ProjectToolLink]

    init(
        yarns: [Yarn]? = nil,
        needles: [Needle]? = nil,
        yarnUsages: [ProjectYarnUsage]? = nil,
        tools: [ToolItem]? = nil,
        projectToolLinks: [ProjectToolLink]? = nil,
        seedSamples: Bool = true,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        let hasExplicitCache = yarns != nil
            || needles != nil
            || yarnUsages != nil
            || tools != nil
            || projectToolLinks != nil
        let resolvedFileURL = fileURL ?? (hasExplicitCache ? nil : Self.defaultFileURL(fileManager: fileManager))

        self.fileManager = fileManager
        self.fileURL = resolvedFileURL
        self.shouldPersist = resolvedFileURL != nil

        if hasExplicitCache {
            self.yarns = yarns ?? (seedSamples ? SampleData.yarns : [])
            self.needles = needles ?? (seedSamples ? SampleData.needles : [])
            self.yarnUsages = yarnUsages ?? []
            self.tools = tools ?? []
            self.projectToolLinks = projectToolLinks ?? []
        } else if let resolvedFileURL {
            let cache = Self.loadLibrary(
                fileURL: resolvedFileURL,
                fileManager: fileManager,
                seedSamples: seedSamples
            )
            self.yarns = cache.yarns
            self.needles = cache.needles
            self.yarnUsages = cache.yarnUsages
            self.tools = cache.tools
            self.projectToolLinks = cache.projectToolLinks
        } else {
            self.yarns = seedSamples ? SampleData.yarns : []
            self.needles = seedSamples ? SampleData.needles : []
            self.yarnUsages = []
            self.tools = []
            self.projectToolLinks = []
        }
    }

    func makeRollbackSnapshot() async -> LocalLibraryRollbackSnapshot {
        LocalLibraryRollbackSnapshot(
            yarns: yarns,
            needles: needles,
            yarnUsages: yarnUsages,
            tools: tools,
            projectToolLinks: projectToolLinks
        )
    }

    func restoreRollbackSnapshot(_ snapshot: LocalLibraryRollbackSnapshot) async throws {
        yarns = snapshot.yarns
        needles = snapshot.needles
        yarnUsages = snapshot.yarnUsages
        tools = snapshot.tools
        projectToolLinks = snapshot.projectToolLinks
        try persistLibrary()
    }

    func fetchYarns() async throws -> [Yarn] {
        yarns.filter { $0.deletedAt == nil }
    }

    func saveYarn(_ yarn: Yarn) async throws {
        if let index = yarns.firstIndex(where: { $0.id == yarn.id }) {
            yarns[index] = yarn
        } else {
            yarns.append(yarn)
        }

        try persistLibrary()
    }

    func deleteYarn(id: UUID) async throws {
        guard let index = yarns.firstIndex(where: { $0.id == id }) else {
            return
        }

        let yarn = yarns[index]
        yarns[index] = Yarn(
            id: yarn.id,
            ownerId: yarn.ownerId,
            name: yarn.name,
            brand: yarn.brand,
            colorway: yarn.colorway,
            weight: yarn.weight,
            quantity: yarn.quantity,
            notes: yarn.notes,
            createdAt: yarn.createdAt,
            updatedAt: Date(),
            deletedAt: Date(),
            syncStatus: .pendingDelete
        )
        try persistLibrary()
    }

    func cacheSyncedYarns(_ remoteYarns: [Yarn]) async {
        for remoteYarn in remoteYarns {
            let syncedYarn = Self.copyYarn(remoteYarn, syncStatus: .synced)

            if let index = yarns.firstIndex(where: { $0.id == remoteYarn.id }) {
                guard !yarns[index].syncStatus.needsUpload else {
                    continue
                }

                yarns[index] = syncedYarn
            } else {
                yarns.append(syncedYarn)
            }
        }

        try? persistLibrary()
    }

    func pendingYarnsForSync() async -> [Yarn] {
        yarns.filter { $0.syncStatus.needsUpload }
    }

    func markYarnSynced(_ yarn: Yarn) async throws {
        try await saveYarn(Self.copyYarn(yarn, syncStatus: .synced))
    }

    func markYarnDeletionSynced(id: UUID) async {
        guard let index = yarns.firstIndex(where: { $0.id == id }) else {
            return
        }

        yarns[index] = Self.copyYarn(yarns[index], syncStatus: .synced)
        try? persistLibrary()
    }

    func discardYarn(id: UUID) async {
        yarns.removeAll { $0.id == id }
        yarnUsages.removeAll { $0.yarnId == id }
        try? persistLibrary()
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        yarnUsages
            .filter { $0.projectId == projectId && $0.deletedAt == nil }
            .sorted { $0.usedAt > $1.usedAt }
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        yarnUsages
            .filter { $0.yarnId == yarnId && $0.deletedAt == nil }
            .sorted { $0.usedAt > $1.usedAt }
    }

    func cacheSyncedYarnUsages(_ remoteUsages: [ProjectYarnUsage]) async {
        for remoteUsage in remoteUsages {
            let syncedUsage = remoteUsage.copy(syncStatus: .synced)

            if let index = yarnUsages.firstIndex(where: { $0.id == remoteUsage.id }) {
                guard !yarnUsages[index].syncStatus.needsUpload else {
                    continue
                }

                yarnUsages[index] = syncedUsage
            } else {
                yarnUsages.append(syncedUsage)
            }
        }

        yarnUsages.sort { $0.usedAt > $1.usedAt }
        try? persistLibrary()
    }

    func pendingYarnUsagesForSync() async -> [ProjectYarnUsage] {
        yarnUsages.filter { $0.syncStatus.needsUpload }
    }

    func markYarnUsageSynced(_ usage: ProjectYarnUsage) async throws {
        if let index = yarnUsages.firstIndex(where: { $0.id == usage.id }) {
            yarnUsages[index] = usage.copy(syncStatus: .synced)
        } else {
            yarnUsages.append(usage.copy(syncStatus: .synced))
        }

        yarnUsages.sort { $0.usedAt > $1.usedAt }
        try persistLibrary()
    }

    func markYarnUsageDeletionSynced(id: UUID) async {
        guard let index = yarnUsages.firstIndex(where: { $0.id == id }) else {
            return
        }

        yarnUsages[index] = yarnUsages[index].copy(syncStatus: .synced)
        try? persistLibrary()
    }

    func discardYarnUsage(id: UUID) async {
        guard let index = yarnUsages.firstIndex(where: { $0.id == id }) else {
            return
        }

        let usage = yarnUsages[index]
        if usage.deletedAt == nil {
            try? adjustYarnQuantity(
                yarnId: usage.yarnId,
                delta: usage.quantityUsed,
                updatedAt: Date()
            )
        }

        yarnUsages.remove(at: index)
        try? persistLibrary()
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        guard usage.quantityUsed > 0 else {
            throw LocalLibraryRepositoryError.invalidQuantity
        }

        let now = Date()
        try adjustYarnQuantity(
            yarnId: usage.yarnId,
            delta: -usage.quantityUsed,
            updatedAt: now
        )
        let savedUsage = ProjectYarnUsage(
            id: usage.id,
            ownerId: usage.ownerId ?? yarns.first(where: { $0.id == usage.yarnId })?.ownerId,
            projectId: usage.projectId,
            projectNameSnapshot: usage.projectNameSnapshot,
            yarnId: usage.yarnId,
            yarnNameSnapshot: usage.yarnNameSnapshot,
            quantityUsed: usage.quantityUsed,
            memo: usage.memo,
            usedAt: usage.usedAt,
            createdAt: usage.createdAt,
            updatedAt: now,
            deletedAt: usage.deletedAt,
            syncStatus: usage.syncStatus
        )

        yarnUsages.insert(savedUsage, at: 0)
        try persistLibrary()

        return savedUsage
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        guard usage.quantityUsed > 0 else {
            throw LocalLibraryRepositoryError.invalidQuantity
        }
        guard let usageIndex = yarnUsages.firstIndex(where: { $0.id == usage.id && $0.deletedAt == nil }) else {
            throw LocalLibraryRepositoryError.yarnUsageNotFound
        }

        let originalUsage = yarnUsages[usageIndex]
        let now = Date()
        try adjustYarnQuantity(
            yarnId: usage.yarnId,
            delta: originalUsage.quantityUsed - usage.quantityUsed,
            updatedAt: now
        )

        let updatedUsage = ProjectYarnUsage(
            id: usage.id,
            ownerId: usage.ownerId ?? originalUsage.ownerId,
            projectId: usage.projectId,
            projectNameSnapshot: usage.projectNameSnapshot ?? originalUsage.projectNameSnapshot,
            yarnId: usage.yarnId,
            yarnNameSnapshot: usage.yarnNameSnapshot,
            quantityUsed: usage.quantityUsed,
            memo: usage.memo,
            usedAt: usage.usedAt,
            createdAt: originalUsage.createdAt,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: usage.syncStatus
        )
        yarnUsages[usageIndex] = updatedUsage
        try persistLibrary()

        return updatedUsage
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
        guard let usageIndex = yarnUsages.firstIndex(where: { $0.id == usage.id && $0.deletedAt == nil }) else {
            throw LocalLibraryRepositoryError.yarnUsageNotFound
        }

        let originalUsage = yarnUsages[usageIndex]
        let now = Date()
        try adjustYarnQuantity(
            yarnId: originalUsage.yarnId,
            delta: originalUsage.quantityUsed,
            updatedAt: now
        )
        yarnUsages[usageIndex] = ProjectYarnUsage(
            id: originalUsage.id,
            ownerId: originalUsage.ownerId,
            projectId: originalUsage.projectId,
            projectNameSnapshot: originalUsage.projectNameSnapshot,
            yarnId: originalUsage.yarnId,
            yarnNameSnapshot: originalUsage.yarnNameSnapshot,
            quantityUsed: originalUsage.quantityUsed,
            memo: originalUsage.memo,
            usedAt: originalUsage.usedAt,
            createdAt: originalUsage.createdAt,
            updatedAt: now,
            deletedAt: now,
            syncStatus: .pendingDelete
        )
        try persistLibrary()
    }

    func fetchNeedles() async throws -> [Needle] {
        needles.filter { $0.deletedAt == nil }
    }

    func saveNeedle(_ needle: Needle) async throws {
        if let index = needles.firstIndex(where: { $0.id == needle.id }) {
            needles[index] = needle
        } else {
            needles.append(needle)
        }

        try persistLibrary()
    }

    func deleteNeedle(id: UUID) async throws {
        guard let index = needles.firstIndex(where: { $0.id == id }) else {
            return
        }

        let needle = needles[index]
        needles[index] = Needle(
            id: needle.id,
            ownerId: needle.ownerId,
            name: needle.name,
            needleType: needle.needleType,
            size: needle.size,
            length: needle.length,
            notes: needle.notes,
            createdAt: needle.createdAt,
            updatedAt: Date(),
            deletedAt: Date(),
            syncStatus: .pendingDelete
        )
        try persistLibrary()
    }

    func cacheSyncedNeedles(_ remoteNeedles: [Needle]) async {
        for remoteNeedle in remoteNeedles {
            let syncedNeedle = Self.copyNeedle(remoteNeedle, syncStatus: .synced)

            if let index = needles.firstIndex(where: { $0.id == remoteNeedle.id }) {
                guard !needles[index].syncStatus.needsUpload else {
                    continue
                }

                needles[index] = syncedNeedle
            } else {
                needles.append(syncedNeedle)
            }
        }

        try? persistLibrary()
    }

    func pendingNeedlesForSync() async -> [Needle] {
        needles.filter { $0.syncStatus.needsUpload }
    }

    func markNeedleSynced(_ needle: Needle) async throws {
        try await saveNeedle(Self.copyNeedle(needle, syncStatus: .synced))
    }

    func markNeedleDeletionSynced(id: UUID) async {
        guard let index = needles.firstIndex(where: { $0.id == id }) else {
            return
        }

        needles[index] = Self.copyNeedle(needles[index], syncStatus: .synced)
        try? persistLibrary()
    }

    func discardNeedle(id: UUID) async {
        needles.removeAll { $0.id == id }
        try? persistLibrary()
    }

    func fetchTools() async throws -> [ToolItem] {
        tools
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                if first.name == second.name {
                    return first.id.uuidString < second.id.uuidString
                }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    func saveTool(_ tool: ToolItem) async throws {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
        } else {
            tools.append(tool)
        }

        try persistLibrary()
    }

    func deleteTool(id: UUID) async throws {
        guard let index = tools.firstIndex(where: { $0.id == id }) else {
            return
        }

        let tool = tools[index]
        let now = Date()
        tools[index] = Self.copyTool(
            tool,
            updatedAt: now,
            deletedAt: now,
            syncStatus: tool.syncStatus == .localOnly ? .localOnly : .pendingDelete
        )

        projectToolLinks = projectToolLinks.map { link in
            guard link.toolId == id, link.deletedAt == nil else {
                return link
            }

            return Self.copyProjectToolLink(
                link,
                updatedAt: now,
                deletedAt: now,
                syncStatus: link.syncStatus == .localOnly ? .localOnly : .pendingDelete
            )
        }

        try persistLibrary()
    }

    func cacheSyncedTools(_ remoteTools: [ToolItem]) async {
        for remoteTool in remoteTools {
            let syncedTool = Self.copyTool(remoteTool, deletedAt: nil, syncStatus: .synced)

            if let index = tools.firstIndex(where: { $0.id == remoteTool.id }) {
                guard !tools[index].syncStatus.needsUpload else {
                    continue
                }

                tools[index] = syncedTool
            } else {
                tools.append(syncedTool)
            }
        }

        try? persistLibrary()
    }

    func pendingToolsForSync() async -> [ToolItem] {
        tools.filter { $0.syncStatus.needsUpload }
    }

    func markToolSynced(_ tool: ToolItem) async throws {
        try await saveTool(Self.copyTool(tool, deletedAt: nil, syncStatus: .synced))
    }

    func markToolDeletionSynced(id: UUID) async {
        tools.removeAll { $0.id == id }
        projectToolLinks.removeAll { $0.toolId == id }
        try? persistLibrary()
    }

    func discardTool(id: UUID) async {
        tools.removeAll { $0.id == id }
        projectToolLinks.removeAll { $0.toolId == id }
        try? persistLibrary()
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        let linkedToolIds = Set(
            projectToolLinks
                .filter { $0.projectId == projectId && $0.deletedAt == nil }
                .map(\.toolId)
        )

        return try await fetchTools()
            .filter { linkedToolIds.contains($0.id) }
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        if tools.contains(where: { $0.id == tool.id }) == false {
            tools.append(tool)
        }

        let now = Date()
        if let index = projectToolLinks.firstIndex(where: { $0.projectId == projectId && $0.toolId == tool.id }) {
            let existingLink = projectToolLinks[index]
            projectToolLinks[index] = ProjectToolLink(
                id: existingLink.id,
                ownerId: existingLink.ownerId ?? tool.ownerId,
                projectId: existingLink.projectId,
                toolId: existingLink.toolId,
                linkedAt: existingLink.linkedAt,
                createdAt: existingLink.createdAt,
                updatedAt: now,
                deletedAt: nil,
                syncStatus: existingLink.syncStatus == .synced ? .pendingUpload : existingLink.syncStatus
            )
        } else {
            projectToolLinks.append(
                ProjectToolLink(
                    ownerId: tool.ownerId,
                    projectId: projectId,
                    toolId: tool.id,
                    linkedAt: now,
                    createdAt: now,
                    updatedAt: now,
                    syncStatus: .localOnly
                )
            )
        }

        try persistLibrary()
        return tool
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
        guard let index = projectToolLinks.firstIndex(where: {
            $0.projectId == projectId && $0.toolId == tool.id && $0.deletedAt == nil
        }) else {
            return
        }

        let link = projectToolLinks[index]
        if link.syncStatus == .localOnly {
            projectToolLinks.remove(at: index)
        } else {
            let now = Date()
            projectToolLinks[index] = Self.copyProjectToolLink(
                link,
                updatedAt: now,
                deletedAt: now,
                syncStatus: .pendingDelete
            )
        }

        try persistLibrary()
    }

    func cacheSyncedProjectTools(_ remoteTools: [ToolItem], forProjectId projectId: UUID) async {
        await cacheSyncedTools(remoteTools)

        let now = Date()
        for tool in remoteTools {
            if let index = projectToolLinks.firstIndex(where: { $0.projectId == projectId && $0.toolId == tool.id }) {
                guard !projectToolLinks[index].syncStatus.needsUpload else {
                    continue
                }

                projectToolLinks[index] = Self.copyProjectToolLink(
                    projectToolLinks[index],
                    updatedAt: now,
                    deletedAt: nil,
                    syncStatus: .synced
                )
            } else {
                projectToolLinks.append(
                    ProjectToolLink(
                        ownerId: tool.ownerId,
                        projectId: projectId,
                        toolId: tool.id,
                        linkedAt: now,
                        createdAt: now,
                        updatedAt: now,
                        syncStatus: .synced
                    )
                )
            }
        }

        try? persistLibrary()
    }

    func pendingProjectToolLinksForSync() async -> [ProjectToolLink] {
        projectToolLinks.filter { $0.syncStatus.needsUpload }
    }

    func markProjectToolLinkedSynced(projectId: UUID, tool: ToolItem) async throws {
        try await markToolSynced(tool)

        let now = Date()
        if let index = projectToolLinks.firstIndex(where: { $0.projectId == projectId && $0.toolId == tool.id }) {
            projectToolLinks[index] = Self.copyProjectToolLink(
                projectToolLinks[index],
                updatedAt: now,
                deletedAt: nil,
                syncStatus: .synced
            )
        } else {
            projectToolLinks.append(
                ProjectToolLink(
                    ownerId: tool.ownerId,
                    projectId: projectId,
                    toolId: tool.id,
                    linkedAt: now,
                    createdAt: now,
                    updatedAt: now,
                    syncStatus: .synced
                )
            )
        }

        try persistLibrary()
    }

    func markProjectToolUnlinkSynced(projectId: UUID, toolId: UUID) async {
        projectToolLinks.removeAll { $0.projectId == projectId && $0.toolId == toolId }
        try? persistLibrary()
    }

    func discardProjectToolLink(projectId: UUID, toolId: UUID) async {
        projectToolLinks.removeAll { $0.projectId == projectId && $0.toolId == toolId }
        try? persistLibrary()
    }

    private func adjustYarnQuantity(yarnId: UUID, delta: Int, updatedAt: Date) throws {
        guard let index = yarns.firstIndex(where: { $0.id == yarnId && $0.deletedAt == nil }) else {
            throw LocalLibraryRepositoryError.yarnNotFound
        }

        let yarn = yarns[index]
        let adjustedQuantity = yarn.quantity + delta
        guard adjustedQuantity >= 0 else {
            throw LocalLibraryRepositoryError.insufficientYarnQuantity
        }

        yarns[index] = Yarn(
            id: yarn.id,
            ownerId: yarn.ownerId,
            name: yarn.name,
            brand: yarn.brand,
            colorway: yarn.colorway,
            weight: yarn.weight,
            quantity: adjustedQuantity,
            notes: yarn.notes,
            createdAt: yarn.createdAt,
            updatedAt: updatedAt,
            deletedAt: yarn.deletedAt,
            syncStatus: yarn.syncStatus
        )
    }

    private func persistLibrary() throws {
        guard shouldPersist, let fileURL else {
            return
        }

        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(
            LibraryCache(
                yarns: yarns,
                needles: needles,
                yarnUsages: yarnUsages,
                tools: tools,
                projectToolLinks: projectToolLinks
            )
        )
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadLibrary(
        fileURL: URL,
        fileManager: FileManager,
        seedSamples: Bool
    ) -> LibraryCache {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let cache = seedSamples ? sampleCache() : emptyCache()
            if seedSamples {
                persistInitialLibrary(cache, fileURL: fileURL, fileManager: fileManager)
            }
            return cache
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(LibraryCache.self, from: data)
        } catch {
            return seedSamples ? sampleCache() : emptyCache()
        }
    }

    private static func persistInitialLibrary(
        _ cache: LibraryCache,
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(cache)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func sampleCache() -> LibraryCache {
        LibraryCache(
            yarns: SampleData.yarns,
            needles: SampleData.needles,
            yarnUsages: [],
            tools: [],
            projectToolLinks: []
        )
    }

    private static func emptyCache() -> LibraryCache {
        LibraryCache(
            yarns: [],
            needles: [],
            yarnUsages: [],
            tools: [],
            projectToolLinks: []
        )
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("library.json")
    }

    private static func copyYarn(
        _ yarn: Yarn,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Yarn {
        Yarn(
            id: yarn.id,
            ownerId: yarn.ownerId,
            name: yarn.name,
            brand: yarn.brand,
            colorway: yarn.colorway,
            weight: yarn.weight,
            quantity: yarn.quantity,
            notes: yarn.notes,
            createdAt: yarn.createdAt,
            updatedAt: updatedAt ?? yarn.updatedAt,
            deletedAt: deletedAt ?? yarn.deletedAt,
            syncStatus: syncStatus ?? yarn.syncStatus
        )
    }

    private static func copyNeedle(
        _ needle: Needle,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Needle {
        Needle(
            id: needle.id,
            ownerId: needle.ownerId,
            name: needle.name,
            needleType: needle.needleType,
            size: needle.size,
            length: needle.length,
            notes: needle.notes,
            createdAt: needle.createdAt,
            updatedAt: updatedAt ?? needle.updatedAt,
            deletedAt: deletedAt ?? needle.deletedAt,
            syncStatus: syncStatus ?? needle.syncStatus
        )
    }

    private static func copyTool(
        _ tool: ToolItem,
        updatedAt: Date? = nil,
        deletedAt: Date?,
        syncStatus: SyncStatus? = nil
    ) -> ToolItem {
        ToolItem(
            id: tool.id,
            ownerId: tool.ownerId,
            name: tool.name,
            type: tool.type,
            link: tool.link,
            memo: tool.memo,
            usageCount: tool.usageCount,
            createdAt: tool.createdAt,
            updatedAt: updatedAt ?? tool.updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus ?? tool.syncStatus
        )
    }

    private static func copyProjectToolLink(
        _ link: ProjectToolLink,
        updatedAt: Date? = nil,
        deletedAt: Date?,
        syncStatus: SyncStatus? = nil
    ) -> ProjectToolLink {
        ProjectToolLink(
            id: link.id,
            ownerId: link.ownerId,
            projectId: link.projectId,
            toolId: link.toolId,
            linkedAt: link.linkedAt,
            createdAt: link.createdAt,
            updatedAt: updatedAt ?? link.updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus ?? link.syncStatus
        )
    }
}

enum LocalLibraryRepositoryError: Error {
    case invalidQuantity
    case yarnNotFound
    case yarnUsageNotFound
    case insufficientYarnQuantity
}

final class LocalGaugeRecordRepository: GaugeRecordRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private var records: [GaugeRecord]

    init(
        records: [GaugeRecord]? = nil,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)

        if let records {
            self.records = records
        } else {
            self.records = Self.loadRecords(
                fileURL: self.fileURL,
                fileManager: fileManager
            )
        }
    }

    func fetchGaugeRecords() async throws -> [GaugeRecord] {
        records
            .filter { $0.deletedAt == nil }
            .sorted { $0.measuredAt > $1.measuredAt }
    }

    func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        let now = Date()
        let saved = record.copy(updatedAt: now)

        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = saved
        } else {
            records.append(saved)
        }

        try persistRecords()
        return saved
    }

    func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        try await saveGaugeRecord(record)
    }

    func makeRollbackSnapshot() async -> [GaugeRecord] {
        records
    }

    func restoreRollbackSnapshot(_ snapshot: [GaugeRecord]) async throws {
        records = snapshot
        try persistRecords()
    }

    func cacheSyncedGaugeRecords(_ remoteRecords: [GaugeRecord]) async throws {
        for remoteRecord in remoteRecords {
            let syncedRecord = remoteRecord.copy(syncStatus: .synced)

            if let index = records.firstIndex(where: { $0.id == remoteRecord.id }) {
                guard !records[index].syncStatus.needsUpload else {
                    continue
                }

                records[index] = syncedRecord
            } else {
                records.append(syncedRecord)
            }
        }

        try persistRecords()
    }

    func pendingGaugeRecordsForSync() async -> [GaugeRecord] {
        records.filter { $0.syncStatus.needsUpload }
    }

    func markGaugeRecordSynced(_ record: GaugeRecord) async throws {
        _ = try await saveGaugeRecord(record.copy(syncStatus: .synced))
    }

    func removeGaugeRecordTombstone(id: UUID) async throws {
        records.removeAll { $0.id == id }
        try persistRecords()
    }

    func deleteGaugeRecord(id: UUID) async throws {
        let deletedAt = Date()

        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index] = records[index].copy(
                syncStatus: .pendingDelete,
                updatedAt: deletedAt,
                deletedAt: deletedAt
            )
            try persistRecords()
        }
    }

    private func persistRecords() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadRecords(
        fileURL: URL,
        fileManager: FileManager
    ) -> [GaugeRecord] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([GaugeRecord].self, from: data)
        } catch {
            return []
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("gauge-records.json")
    }
}

@MainActor
final class OfflineFirstGaugeRecordRepository: GaugeRecordRepository {
    private let local: LocalGaugeRecordRepository
    private let remote: any GaugeRecordRepository

    init(
        local: LocalGaugeRecordRepository,
        remote: any GaugeRecordRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchGaugeRecords() async throws -> [GaugeRecord] {
        await syncPendingChanges()

        do {
            let remoteRecords = try await remote.fetchGaugeRecords()
            try await local.cacheSyncedGaugeRecords(remoteRecords)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchGaugeRecords()
    }

    func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localRecord = record.copy(
            syncStatus: localSaveSyncStatus(for: record.syncStatus)
        )
        let savedRecord = try await local.saveGaugeRecord(localRecord)

        let uploadRecord = record.copy(
            syncStatus: uploadSyncStatus(for: record.syncStatus)
        )

        do {
            let syncedRecord = try await remote.saveGaugeRecord(uploadRecord)
            try await local.markGaugeRecordSynced(syncedRecord)
            return syncedRecord
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return savedRecord
        }
    }

    func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localRecord = record.copy(
            syncStatus: localSaveSyncStatus(for: .pendingUpload)
        )
        let savedRecord = try await local.updateGaugeRecord(localRecord)

        let uploadRecord = record.copy(syncStatus: .synced)

        do {
            let syncedRecord = try await remote.updateGaugeRecord(uploadRecord)
            try await local.markGaugeRecordSynced(syncedRecord)
            return syncedRecord
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return savedRecord
        }
    }

    func deleteGaugeRecord(id: UUID) async throws {
        let existingRecord = try await local.fetchGaugeRecords().first { $0.id == id }
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteGaugeRecord(id: id)

        guard existingRecord?.syncStatus != .localOnly else {
            try await local.removeGaugeRecordTombstone(id: id)
            return
        }

        do {
            try await remote.deleteGaugeRecord(id: id)
            try await local.removeGaugeRecordTombstone(id: id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    private func syncPendingChanges() async {
        for record in await local.pendingGaugeRecordsForSync() {
            do {
                if record.syncStatus == .pendingDelete {
                    try await remote.deleteGaugeRecord(id: record.id)
                    try await local.removeGaugeRecordTombstone(id: record.id)
                } else if record.syncStatus == .pendingUpload {
                    let syncedRecord = try await remote.updateGaugeRecord(record.copy(syncStatus: .synced))
                    try await local.markGaugeRecordSynced(syncedRecord)
                } else {
                    let syncedRecord = try await remote.saveGaugeRecord(record)
                    try await local.markGaugeRecordSynced(syncedRecord)
                }
            } catch {
                await resolveRejectedPendingChange(record, after: error)
            }
        }
    }

    private func resolveRejectedPendingChange(
        _ record: GaugeRecord,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch record.syncStatus {
        case .localOnly, .pendingDelete:
            try? await local.removeGaugeRecordTombstone(id: record.id)
        case .pendingUpload:
            do {
                if let serverRecord = try await remote.fetchGaugeRecords().first(where: { $0.id == record.id }) {
                    try await local.markGaugeRecordSynced(serverRecord)
                } else {
                    try await local.removeGaugeRecordTombstone(id: record.id)
                }
            } catch {
                if !shouldDefer(error) {
                    try? await local.removeGaugeRecordTombstone(id: record.id)
                }
            }
        default:
            break
        }
    }

    private func shouldDefer(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        if let apiError = error as? APIError,
           let statusCode = apiError.statusCode {
            return statusCode >= 500
        }

        return false
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: [GaugeRecord],
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }

    private func localSaveSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        switch syncStatus {
        case .synced, .pendingUpload:
            return .pendingUpload
        default:
            return .localOnly
        }
    }

    private func uploadSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        syncStatus == .pendingUpload ? .synced : syncStatus
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
        seedSamples: Bool = true,
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
                fileManager: fileManager,
                seedSamples: seedSamples
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

    func makeRollbackSnapshot() async -> [Skill] {
        skills
    }

    func restoreRollbackSnapshot(_ snapshot: [Skill]) async throws {
        skills = snapshot
        try persistSkills()
    }

    func deleteSkill(id: UUID) async throws {
        guard let index = skills.firstIndex(where: { $0.id == id }) else {
            return
        }

        skills[index] = Self.copySkill(
            skills[index],
            updatedAt: Date(),
            deletedAt: Date(),
            syncStatus: .pendingDelete
        )
        try persistSkills()
    }

    func cacheSyncedSkills(_ remoteSkills: [Skill]) async throws {
        for remoteSkill in remoteSkills {
            let syncedSkill = Self.copySkill(remoteSkill, syncStatus: .synced)

            if let index = skills.firstIndex(where: { $0.id == remoteSkill.id }) {
                guard !skills[index].syncStatus.needsUpload else {
                    continue
                }

                skills[index] = syncedSkill
            } else {
                skills.append(syncedSkill)
            }
        }

        try persistSkills()
    }

    func pendingSkillsForSync() async -> [Skill] {
        skills.filter { $0.syncStatus.needsUpload }
    }

    func markSkillSynced(_ skill: Skill) async throws {
        try await saveSkill(Self.copySkill(skill, syncStatus: .synced))
    }

    func removeSkillTombstone(id: UUID) async throws {
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
        fileManager: FileManager,
        seedSamples: Bool
    ) -> [Skill] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            guard seedSamples else {
                return []
            }

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
            return seedSamples ? SampleData.skills : []
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

    private static func copySkill(
        _ skill: Skill,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Skill {
        Skill(
            id: skill.id,
            ownerId: skill.ownerId,
            name: skill.name,
            abbreviation: skill.abbreviation,
            description: skill.description,
            category: skill.category,
            difficulty: skill.difficulty,
            animationName: skill.animationName,
            animationType: skill.animationType,
            isSystem: skill.isSystem,
            userLevel: skill.userLevel,
            createdAt: skill.createdAt,
            updatedAt: updatedAt ?? skill.updatedAt,
            deletedAt: deletedAt ?? skill.deletedAt,
            syncStatus: syncStatus ?? skill.syncStatus,
            steps: skill.steps,
            animationIds: skill.animationIds
        )
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("skills.json")
    }
}

final class LocalDictionaryRepository: DictionaryRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private var terms: [DictionaryTerm]

    init(
        terms: [DictionaryTerm]? = nil,
        seedSamples: Bool = true,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)

        if let terms {
            self.terms = terms
        } else {
            self.terms = Self.loadTerms(
                fileURL: self.fileURL,
                fileManager: fileManager,
                seedSamples: seedSamples
            )
        }
    }

    func fetchTerms() async throws -> [DictionaryTerm] {
        terms
            .filter { $0.deletedAt == nil }
            .sorted { $0.term.localizedStandardCompare($1.term) == .orderedAscending }
    }

    func fetchTerm(id: UUID) async throws -> DictionaryTerm? {
        terms.first { $0.id == id && $0.deletedAt == nil }
    }

    func saveTerm(_ term: DictionaryTerm) async throws {
        if let index = terms.firstIndex(where: { $0.id == term.id }) {
            terms[index] = term
        } else {
            terms.append(term)
        }

        try persistTerms()
    }

    func makeRollbackSnapshot() async -> [DictionaryTerm] {
        terms
    }

    func restoreRollbackSnapshot(_ snapshot: [DictionaryTerm]) async throws {
        terms = snapshot
        try persistTerms()
    }

    func deleteTerm(id: UUID) async throws {
        guard let index = terms.firstIndex(where: { $0.id == id }) else {
            return
        }

        terms[index] = terms[index].copy(
            updatedAt: Date(),
            deletedAt: Date(),
            syncStatus: .pendingDelete
        )
        try persistTerms()
    }

    func cacheSyncedTerms(_ remoteTerms: [DictionaryTerm]) async throws {
        for remoteTerm in remoteTerms {
            let syncedTerm = remoteTerm.copy(syncStatus: .synced)

            if let index = terms.firstIndex(where: { $0.id == remoteTerm.id }) {
                guard !terms[index].syncStatus.needsUpload else {
                    continue
                }

                terms[index] = syncedTerm
            } else {
                terms.append(syncedTerm)
            }
        }

        try persistTerms()
    }

    func pendingTermsForSync() async -> [DictionaryTerm] {
        terms.filter { $0.syncStatus.needsUpload }
    }

    func markTermSynced(_ term: DictionaryTerm) async throws {
        try await saveTerm(term.copy(syncStatus: .synced))
    }

    func removeTermTombstone(id: UUID) async throws {
        terms.removeAll { $0.id == id }
        try persistTerms()
    }

    private func persistTerms() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(terms)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadTerms(
        fileURL: URL,
        fileManager: FileManager,
        seedSamples: Bool
    ) -> [DictionaryTerm] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            guard seedSamples else {
                return []
            }

            let sampleTerms = SampleData.dictionaryTerms
            persistInitialTerms(sampleTerms, fileURL: fileURL, fileManager: fileManager)
            return sampleTerms
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([DictionaryTerm].self, from: data)
        } catch {
            return seedSamples ? SampleData.dictionaryTerms : []
        }
    }

    private static func persistInitialTerms(
        _ terms: [DictionaryTerm],
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(terms)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("dictionary-terms.json")
    }
}

final class LocalProfileRepository: ProfileRepository {
    private let fileURL: URL?
    private let fileManager: FileManager
    private let shouldPersist: Bool
    private var profile: UserProfile?

    init(
        profile: UserProfile? = nil,
        seedSample: Bool = true,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        let hasExplicitProfile = profile != nil
        let resolvedFileURL = fileURL ?? (hasExplicitProfile ? nil : Self.defaultFileURL(fileManager: fileManager))

        self.fileManager = fileManager
        self.fileURL = resolvedFileURL
        self.shouldPersist = resolvedFileURL != nil

        if let profile {
            self.profile = profile
        } else if let resolvedFileURL {
            self.profile = Self.loadProfile(
                fileURL: resolvedFileURL,
                fileManager: fileManager,
                seedSample: seedSample
            )
        } else {
            self.profile = seedSample ? SampleData.profile : nil
        }
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        guard let profile else {
            throw LocalProfileRepositoryError.profileNotFound
        }

        return profile
    }

    func saveCurrentProfile(_ profile: UserProfile) async throws {
        self.profile = profile
        try persistProfile()
    }

    func makeRollbackSnapshot() async -> UserProfile? {
        profile
    }

    func restoreRollbackSnapshot(_ snapshot: UserProfile?) async throws {
        profile = snapshot
        try persistProfile()
    }

    func cacheSyncedProfile(_ profile: UserProfile) async {
        guard self.profile?.syncStatus.needsUpload != true else {
            return
        }

        self.profile = Self.copyProfile(profile, syncStatus: .synced)
        try? persistProfile()
    }

    func pendingProfileForSync() async -> UserProfile? {
        guard profile?.syncStatus.needsUpload == true else {
            return nil
        }

        return profile
    }

    func markProfileSynced(_ profile: UserProfile) async throws {
        try await saveCurrentProfile(Self.copyProfile(profile, syncStatus: .synced))
    }

    private func persistProfile() throws {
        guard shouldPersist, let fileURL else {
            return
        }

        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadProfile(
        fileURL: URL,
        fileManager: FileManager,
        seedSample: Bool
    ) -> UserProfile? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            guard seedSample else {
                return nil
            }

            let sampleProfile = SampleData.profile
            persistInitialProfile(sampleProfile, fileURL: fileURL, fileManager: fileManager)
            return sampleProfile
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(UserProfile?.self, from: data)
        } catch {
            return seedSample ? SampleData.profile : nil
        }
    }

    private static func persistInitialProfile(
        _ profile: UserProfile,
        fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(profile)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("profile.json")
    }

    private static func copyProfile(
        _ profile: UserProfile,
        syncStatus: SyncStatus
    ) -> UserProfile {
        UserProfile(
            id: profile.id,
            ownerId: profile.ownerId,
            displayName: profile.displayName,
            preferredUnits: profile.preferredUnits,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            deletedAt: profile.deletedAt,
            syncStatus: syncStatus
        )
    }
}

enum LocalProfileRepositoryError: Error {
    case profileNotFound
}

final class LocalAuthRepository: AuthRepository {
    func register(
        email: String,
        password: String,
        displayName: String,
        preferredUnits: String
    ) async throws -> AuthSession {
        throw AuthRepositoryError.serverUnavailable
    }

    func login(email: String, password: String) async throws -> AuthSession {
        throw AuthRepositoryError.serverUnavailable
    }

    func fetchCurrentUser() async throws -> AuthUser {
        throw AuthRepositoryError.serverUnavailable
    }
}
