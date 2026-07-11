//
//  DataBackupExportViewModel.swift
//  KnitGether
//
//  Created by Codex on 7/10/26.
//

import Combine
import Foundation

struct SettingsBackupSnapshot: Codable {
    let schemaVersion: Int
    let generatedAt: Date
    let profile: UserProfile?
    let projects: [KnittingProject]
    let patterns: [PatternDocument]
    let yarns: [Yarn]
    let needles: [Needle]
    let tools: [ToolItem]
    let skills: [Skill]
    let dictionaryTerms: [DictionaryTerm]
    let gaugeRecords: [GaugeRecord]
    let yarnUsagesByProjectId: [String: [ProjectYarnUsage]]
    let toolIdsByProjectId: [String: [UUID]]
    let progressPhotosByProjectId: [String: [ProjectProgressPhoto]]
    let progressPhotoFilesByPhotoId: [String: Data]

    init(
        schemaVersion: Int,
        generatedAt: Date,
        profile: UserProfile?,
        projects: [KnittingProject],
        patterns: [PatternDocument],
        yarns: [Yarn],
        needles: [Needle],
        tools: [ToolItem],
        skills: [Skill],
        dictionaryTerms: [DictionaryTerm],
        gaugeRecords: [GaugeRecord],
        yarnUsagesByProjectId: [String: [ProjectYarnUsage]] = [:],
        toolIdsByProjectId: [String: [UUID]] = [:],
        progressPhotosByProjectId: [String: [ProjectProgressPhoto]] = [:],
        progressPhotoFilesByPhotoId: [String: Data] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.profile = profile
        self.projects = projects
        self.patterns = patterns
        self.yarns = yarns
        self.needles = needles
        self.tools = tools
        self.skills = skills
        self.dictionaryTerms = dictionaryTerms
        self.gaugeRecords = gaugeRecords
        self.yarnUsagesByProjectId = yarnUsagesByProjectId
        self.toolIdsByProjectId = toolIdsByProjectId
        self.progressPhotosByProjectId = progressPhotosByProjectId
        self.progressPhotoFilesByPhotoId = progressPhotoFilesByPhotoId
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case generatedAt
        case profile
        case projects
        case patterns
        case yarns
        case needles
        case tools
        case skills
        case dictionaryTerms
        case gaugeRecords
        case yarnUsagesByProjectId
        case toolIdsByProjectId
        case progressPhotosByProjectId
        case progressPhotoFilesByPhotoId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
        projects = try container.decodeIfPresent([KnittingProject].self, forKey: .projects) ?? []
        patterns = try container.decodeIfPresent([PatternDocument].self, forKey: .patterns) ?? []
        yarns = try container.decodeIfPresent([Yarn].self, forKey: .yarns) ?? []
        needles = try container.decodeIfPresent([Needle].self, forKey: .needles) ?? []
        tools = try container.decodeIfPresent([ToolItem].self, forKey: .tools) ?? []
        skills = try container.decodeIfPresent([Skill].self, forKey: .skills) ?? []
        dictionaryTerms = try container.decodeIfPresent([DictionaryTerm].self, forKey: .dictionaryTerms) ?? []
        gaugeRecords = try container.decodeIfPresent([GaugeRecord].self, forKey: .gaugeRecords) ?? []
        yarnUsagesByProjectId = try container.decodeIfPresent([String: [ProjectYarnUsage]].self, forKey: .yarnUsagesByProjectId) ?? [:]
        toolIdsByProjectId = try container.decodeIfPresent([String: [UUID]].self, forKey: .toolIdsByProjectId) ?? [:]
        progressPhotosByProjectId = try container.decodeIfPresent([String: [ProjectProgressPhoto]].self, forKey: .progressPhotosByProjectId) ?? [:]
        progressPhotoFilesByPhotoId = try container.decodeIfPresent([String: Data].self, forKey: .progressPhotoFilesByPhotoId) ?? [:]
    }
}

@MainActor
final class DataBackupExportViewModel: ObservableObject {
    @Published private(set) var backupFileURL: URL?
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isExporting = false

    private let profileRepository: any ProfileRepository
    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository
    private let dictionaryRepository: any DictionaryRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let progressPhotoRepository: any ProjectProgressPhotoRepository
    private let exportDirectoryURL: URL
    private let fileManager: FileManager
    private let nowProvider: () -> Date

    init(
        profileRepository: any ProfileRepository,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository,
        gaugeRecordRepository: any GaugeRecordRepository,
        progressPhotoRepository: any ProjectProgressPhotoRepository,
        exportDirectoryURL: URL = FileManager.default.temporaryDirectory,
        fileManager: FileManager = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.profileRepository = profileRepository
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.dictionaryRepository = dictionaryRepository
        self.gaugeRecordRepository = gaugeRecordRepository
        self.progressPhotoRepository = progressPhotoRepository
        self.exportDirectoryURL = exportDirectoryURL
        self.fileManager = fileManager
        self.nowProvider = nowProvider
    }

    @discardableResult
    func exportBackup() async -> URL? {
        guard !isExporting else {
            return nil
        }

        isExporting = true
        defer { isExporting = false }

        do {
            let generatedAt = nowProvider()
            let snapshot = try await makeSnapshot(generatedAt: generatedAt)
            let url = try write(snapshot: snapshot, generatedAt: generatedAt)
            backupFileURL = url
            statusMessage = "백업 파일을 만들었어요."
            errorMessage = nil
            return url
        } catch {
            backupFileURL = nil
            statusMessage = nil
            errorMessage = "백업 파일을 만들지 못했어요."
            return nil
        }
    }

    private func makeSnapshot(generatedAt: Date) async throws -> SettingsBackupSnapshot {
        let profile = try? await profileRepository.fetchCurrentProfile()
        let projects = try await projectRepository.fetchProjects()
        let patterns = try await patternRepository.fetchPatterns()
        let yarns = try await libraryRepository.fetchYarns()
        let needles = try await libraryRepository.fetchNeedles()
        let tools = try await libraryRepository.fetchTools()
        let skills = try await skillRepository.fetchSkills()
        let dictionaryTerms = try await dictionaryRepository.fetchTerms()
        let gaugeRecords = try await gaugeRecordRepository.fetchGaugeRecords()

        var yarnUsagesByProjectId: [String: [ProjectYarnUsage]] = [:]
        var toolIdsByProjectId: [String: [UUID]] = [:]
        var progressPhotosByProjectId: [String: [ProjectProgressPhoto]] = [:]
        var progressPhotoFilesByPhotoId: [String: Data] = [:]
        for project in projects {
            let key = project.id.uuidString.lowercased()
            yarnUsagesByProjectId[key] = (try? await libraryRepository.fetchYarnUsages(forProjectId: project.id)) ?? []
            toolIdsByProjectId[key] = ((try? await libraryRepository.fetchTools(forProjectId: project.id)) ?? []).map(\.id)
            let progressPhotos = (try? await progressPhotoRepository.fetchProgressPhotos(projectId: project.id)) ?? []
            progressPhotosByProjectId[key] = progressPhotos

            for photo in progressPhotos {
                guard let fileURL = progressPhotoRepository.fileURL(for: photo),
                      let fileData = try? Data(contentsOf: fileURL)
                else {
                    continue
                }

                progressPhotoFilesByPhotoId[photo.id.uuidString.lowercased()] = fileData
            }
        }

        return SettingsBackupSnapshot(
            schemaVersion: 1,
            generatedAt: generatedAt,
            profile: profile,
            projects: projects,
            patterns: patterns,
            yarns: yarns,
            needles: needles,
            tools: tools,
            skills: skills,
            dictionaryTerms: dictionaryTerms,
            gaugeRecords: gaugeRecords,
            yarnUsagesByProjectId: yarnUsagesByProjectId,
            toolIdsByProjectId: toolIdsByProjectId,
            progressPhotosByProjectId: progressPhotosByProjectId,
            progressPhotoFilesByPhotoId: progressPhotoFilesByPhotoId
        )
    }

    private func write(
        snapshot: SettingsBackupSnapshot,
        generatedAt: Date
    ) throws -> URL {
        try fileManager.createDirectory(
            at: exportDirectoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        let fileURL = exportDirectoryURL
            .appendingPathComponent("KnitGether-Backup-\(fileTimestamp(for: generatedAt)).json")
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    private func fileTimestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}

@MainActor
final class DataBackupImportViewModel: ObservableObject {
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isImporting = false

    private let profileRepository: any ProfileRepository
    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository
    private let dictionaryRepository: any DictionaryRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let progressPhotoRepository: any ProjectProgressPhotoRepository

    init(
        profileRepository: any ProfileRepository,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository,
        gaugeRecordRepository: any GaugeRecordRepository,
        progressPhotoRepository: any ProjectProgressPhotoRepository
    ) {
        self.profileRepository = profileRepository
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.dictionaryRepository = dictionaryRepository
        self.gaugeRecordRepository = gaugeRecordRepository
        self.progressPhotoRepository = progressPhotoRepository
    }

    @discardableResult
    func importBackup(from fileURL: URL) async -> Bool {
        guard !isImporting else {
            return false
        }

        isImporting = true
        defer { isImporting = false }

        do {
            let snapshot = try decodeSnapshot(from: fileURL)
            let skippedProgressPhotoCount = try await restore(snapshot)
            statusMessage = skippedProgressPhotoCount == 0
                ? "백업 파일을 가져왔어요."
                : "백업 파일을 가져왔어요. 파일 데이터가 없는 진행 사진 \(skippedProgressPhotoCount)개는 건너뛰었어요."
            errorMessage = nil
            return true
        } catch {
            statusMessage = nil
            errorMessage = "백업 파일을 가져오지 못했어요."
            return false
        }
    }

    func markImportSelectionFailed() {
        statusMessage = nil
        errorMessage = "백업 파일을 선택하지 못했어요."
    }

    private func decodeSnapshot(from fileURL: URL) throws -> SettingsBackupSnapshot {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(SettingsBackupSnapshot.self, from: data)

        guard snapshot.schemaVersion == 1 else {
            throw DataBackupImportError.unsupportedSchema
        }

        return snapshot
    }

    private func restore(_ snapshot: SettingsBackupSnapshot) async throws -> Int {
        if let profile = snapshot.profile {
            try await profileRepository.saveCurrentProfile(profile)
        }

        let existingProjectIds = Set((try? await projectRepository.fetchProjects().map(\.id)) ?? [])
        let existingPatternIds = Set((try? await patternRepository.fetchPatterns().map(\.id)) ?? [])
        let existingYarnIds = Set((try? await libraryRepository.fetchYarns().map(\.id)) ?? [])
        let existingNeedleIds = Set((try? await libraryRepository.fetchNeedles().map(\.id)) ?? [])
        let existingToolIds = Set((try? await libraryRepository.fetchTools().map(\.id)) ?? [])
        let existingSkillIds = Set((try? await skillRepository.fetchSkills().map(\.id)) ?? [])
        let existingTermIds = Set((try? await dictionaryRepository.fetchTerms().map(\.id)) ?? [])
        let existingGaugeRecordIds = Set((try? await gaugeRecordRepository.fetchGaugeRecords().map(\.id)) ?? [])

        for pattern in snapshot.patterns {
            try await patternRepository.savePattern(pattern.copy(syncStatus: importSyncStatus(for: pattern.id, existingIds: existingPatternIds)))
        }

        for yarn in snapshot.yarns {
            try await libraryRepository.saveYarn(copyYarn(yarn, syncStatus: importSyncStatus(for: yarn.id, existingIds: existingYarnIds)))
        }

        for needle in snapshot.needles {
            try await libraryRepository.saveNeedle(copyNeedle(needle, syncStatus: importSyncStatus(for: needle.id, existingIds: existingNeedleIds)))
        }

        for tool in snapshot.tools {
            try await libraryRepository.saveTool(tool.copy(syncStatus: importSyncStatus(for: tool.id, existingIds: existingToolIds)))
        }

        for project in snapshot.projects {
            try await projectRepository.saveProject(project.copy(syncStatus: importSyncStatus(for: project.id, existingIds: existingProjectIds)))
        }

        for skill in snapshot.skills {
            try await skillRepository.saveSkill(copySkill(skill, syncStatus: importSyncStatus(for: skill.id, existingIds: existingSkillIds)))
        }

        for term in snapshot.dictionaryTerms {
            try await dictionaryRepository.saveTerm(term.copy(syncStatus: importSyncStatus(for: term.id, existingIds: existingTermIds)))
        }

        for record in snapshot.gaugeRecords {
            let recordToSave = record.copy(syncStatus: importSyncStatus(for: record.id, existingIds: existingGaugeRecordIds))
            if existingGaugeRecordIds.contains(record.id) {
                _ = try await gaugeRecordRepository.updateGaugeRecord(recordToSave)
            } else {
                _ = try await gaugeRecordRepository.saveGaugeRecord(recordToSave)
            }
        }

        try await restoreYarnUsages(snapshot)
        try await restoreToolLinks(snapshot)
        return try await restoreProgressPhotos(snapshot)
    }

    private func restoreYarnUsages(_ snapshot: SettingsBackupSnapshot) async throws {
        for project in snapshot.projects {
            let key = project.id.uuidString.lowercased()
            let usages = snapshot.yarnUsagesByProjectId[key] ?? []
            let existingIds = Set((try? await libraryRepository.fetchYarnUsages(forProjectId: project.id).map(\.id)) ?? [])

            for usage in usages {
                if existingIds.contains(usage.id) {
                    _ = try await libraryRepository.updateYarnUsage(usage.copy(syncStatus: .synced))
                } else {
                    _ = try await libraryRepository.recordYarnUsage(usage.copy(syncStatus: .localOnly))
                }
            }
        }

        for yarn in snapshot.yarns {
            try await libraryRepository.saveYarn(copyYarn(yarn, syncStatus: .synced))
        }
    }

    private func restoreToolLinks(_ snapshot: SettingsBackupSnapshot) async throws {
        let toolsById = Dictionary(uniqueKeysWithValues: snapshot.tools.map { ($0.id, $0) })

        for project in snapshot.projects {
            let key = project.id.uuidString.lowercased()
            let toolIds = snapshot.toolIdsByProjectId[key] ?? []

            for toolId in toolIds {
                guard let tool = toolsById[toolId] else {
                    continue
                }

                _ = try await libraryRepository.linkTool(tool, toProjectId: project.id)
            }
        }
    }

    private func restoreProgressPhotos(_ snapshot: SettingsBackupSnapshot) async throws -> Int {
        var skippedCount = 0

        for project in snapshot.projects {
            let key = project.id.uuidString.lowercased()
            let photos = snapshot.progressPhotosByProjectId[key] ?? []
            guard !photos.isEmpty else {
                continue
            }

            let existingPhotos = try await progressPhotoRepository.fetchProgressPhotos(projectId: project.id)
            let existingPhotosById = Dictionary(uniqueKeysWithValues: existingPhotos.map { ($0.id, $0) })

            for photo in photos {
                if let existingPhoto = existingPhotosById[photo.id] {
                    _ = try await progressPhotoRepository.updateProgressPhoto(
                        existingPhoto,
                        caption: photo.caption,
                        takenAt: photo.takenAt
                    )
                    continue
                }

                guard let fileData = snapshot.progressPhotoFilesByPhotoId[photo.id.uuidString.lowercased()] else {
                    skippedCount += 1
                    continue
                }

                _ = try await progressPhotoRepository.createProgressPhoto(
                    projectId: project.id,
                    imageData: fileData,
                    fileName: photo.fileName,
                    contentType: photo.contentType,
                    caption: photo.caption,
                    takenAt: photo.takenAt
                )
            }
        }

        return skippedCount
    }

    private func importSyncStatus(
        for id: UUID,
        existingIds: Set<UUID>
    ) -> SyncStatus {
        existingIds.contains(id) ? .synced : .localOnly
    }

    private func copyYarn(_ yarn: Yarn, syncStatus: SyncStatus) -> Yarn {
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
            updatedAt: yarn.updatedAt,
            deletedAt: yarn.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copyNeedle(_ needle: Needle, syncStatus: SyncStatus) -> Needle {
        Needle(
            id: needle.id,
            ownerId: needle.ownerId,
            name: needle.name,
            needleType: needle.needleType,
            size: needle.size,
            length: needle.length,
            notes: needle.notes,
            createdAt: needle.createdAt,
            updatedAt: needle.updatedAt,
            deletedAt: needle.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copySkill(_ skill: Skill, syncStatus: SyncStatus) -> Skill {
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
            updatedAt: skill.updatedAt,
            deletedAt: skill.deletedAt,
            syncStatus: syncStatus,
            steps: skill.steps,
            animationIds: skill.animationIds
        )
    }
}

private enum DataBackupImportError: Error {
    case unsupportedSchema
}
