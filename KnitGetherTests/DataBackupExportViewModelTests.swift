import Foundation
import Testing
@testable import KnitGether

@MainActor
struct DataBackupExportViewModelTests {
    @Test func exportBackupWritesReadableSnapshotFile() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataBackupExportViewModelTests-\(UUID().uuidString)", isDirectory: true)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let project = SampleData.projects[0]
        let yarn = SampleData.yarns[0]
        let tool = ToolItem(
            ownerId: SampleData.ownerId,
            name: "Cable Needle",
            type: "Cable",
            memo: "For sleeves",
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let yarnUsage = ProjectYarnUsage(
            ownerId: SampleData.ownerId,
            projectId: project.id,
            projectNameSnapshot: project.name,
            yarnId: yarn.id,
            yarnNameSnapshot: yarn.name,
            quantityUsed: 1,
            memo: "Body",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let toolLink = ProjectToolLink(
            ownerId: SampleData.ownerId,
            projectId: project.id,
            toolId: tool.id,
            linkedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let progressPhotoRepository = LocalProjectProgressPhotoRepository(
            photos: [],
            fileURL: directoryURL.appendingPathComponent("export-progress-photos.json"),
            fileStore: LocalProjectProgressPhotoFileStore(
                rootDirectoryURL: directoryURL.appendingPathComponent("export-files", isDirectory: true)
            )
        )
        let photo = try await progressPhotoRepository.createProgressPhoto(
            projectId: project.id,
            imageData: Data([1, 2, 3, 4]),
            fileName: "progress.jpg",
            contentType: "image/jpeg",
            caption: "Sleeve progress",
            takenAt: now
        )
        let viewModel = DataBackupExportViewModel(
            profileRepository: LocalProfileRepository(profile: SampleData.profile),
            projectRepository: LocalProjectRepository(projects: [project]),
            patternRepository: LocalPatternRepository(patterns: [SampleData.patternDocuments[0]]),
            libraryRepository: LocalLibraryRepository(
                yarns: [yarn],
                needles: [SampleData.needles[0]],
                yarnUsages: [yarnUsage],
                tools: [tool],
                projectToolLinks: [toolLink],
                seedSamples: false
            ),
            skillRepository: LocalSkillRepository(skills: [SampleData.skills[0]], seedSamples: false),
            dictionaryRepository: LocalDictionaryRepository(terms: [SampleData.dictionaryTerms[0]], seedSamples: false),
            gaugeRecordRepository: LocalGaugeRecordRepository(records: []),
            progressPhotoRepository: progressPhotoRepository,
            exportDirectoryURL: directoryURL,
            nowProvider: { now }
        )

        let exportedURL = await viewModel.exportBackup()

        let url = try #require(exportedURL)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(SettingsBackupSnapshot.self, from: data)

        #expect(snapshot.schemaVersion == 1)
        #expect(snapshot.profile?.displayName == SampleData.profile.displayName)
        #expect(snapshot.projects.map(\.id) == [project.id])
        #expect(snapshot.patterns.count == 1)
        #expect(snapshot.yarns.count == 1)
        #expect(snapshot.needles.count == 1)
        #expect(snapshot.tools.map(\.id) == [tool.id])
        #expect(snapshot.yarnUsagesByProjectId[project.id.uuidString.lowercased()]?.map(\.id) == [yarnUsage.id])
        #expect(snapshot.toolIdsByProjectId[project.id.uuidString.lowercased()] == [tool.id])
        #expect(snapshot.skills.count == 1)
        #expect(snapshot.dictionaryTerms.count == 1)
        #expect(snapshot.progressPhotosByProjectId[project.id.uuidString.lowercased()]?.count == 1)
        #expect(snapshot.progressPhotoFilesByPhotoId[photo.id.uuidString.lowercased()] == Data([1, 2, 3, 4]))
        #expect(viewModel.backupFileURL == url)
        #expect(viewModel.statusMessage == "백업 파일을 만들었어요.")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func importBackupRestoresSnapshotIntoRepositories() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataBackupImportViewModelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let project = SampleData.projects[0]
        let yarn = SampleData.yarns[0]
        let needle = SampleData.needles[0]
        let tool = ToolItem(
            ownerId: SampleData.ownerId,
            name: "Cable Needle",
            type: "Cable",
            memo: "For sleeves",
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let usage = ProjectYarnUsage(
            ownerId: SampleData.ownerId,
            projectId: project.id,
            projectNameSnapshot: project.name,
            yarnId: yarn.id,
            yarnNameSnapshot: yarn.name,
            quantityUsed: 1,
            memo: "Restored usage",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let photo = ProjectProgressPhoto(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            ownerId: SampleData.ownerId,
            projectId: project.id,
            fileName: "restored-progress.jpg",
            contentType: "image/jpeg",
            byteSize: 4,
            localFilePath: nil,
            caption: "Restored progress",
            takenAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
        let snapshot = SettingsBackupSnapshot(
            schemaVersion: 1,
            generatedAt: now,
            profile: SampleData.profile,
            projects: [project],
            patterns: [SampleData.patternDocuments[0]],
            yarns: [yarn],
            needles: [needle],
            tools: [tool],
            skills: [SampleData.skills[0]],
            dictionaryTerms: [SampleData.dictionaryTerms[0]],
            gaugeRecords: [],
            yarnUsagesByProjectId: [project.id.uuidString.lowercased(): [usage]],
            toolIdsByProjectId: [project.id.uuidString.lowercased(): [tool.id]],
            progressPhotosByProjectId: [project.id.uuidString.lowercased(): [photo]],
            progressPhotoFilesByPhotoId: [photo.id.uuidString.lowercased(): Data([5, 6, 7, 8])]
        )
        let backupURL = directoryURL.appendingPathComponent("backup.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: backupURL)

        let profileRepository = LocalProfileRepository(profile: nil, seedSample: false)
        let projectRepository = LocalProjectRepository(projects: [], seedSamples: false)
        let patternRepository = LocalPatternRepository(patterns: [], seedSamples: false)
        let libraryRepository = LocalLibraryRepository(
            yarns: [],
            needles: [],
            yarnUsages: [],
            tools: [],
            projectToolLinks: [],
            seedSamples: false
        )
        let skillRepository = LocalSkillRepository(skills: [], seedSamples: false)
        let dictionaryRepository = LocalDictionaryRepository(terms: [], seedSamples: false)
        let gaugeRecordRepository = LocalGaugeRecordRepository(records: [])
        let progressPhotoRepository = LocalProjectProgressPhotoRepository(
            photos: [],
            fileURL: directoryURL.appendingPathComponent("import-progress-photos.json"),
            fileStore: LocalProjectProgressPhotoFileStore(
                rootDirectoryURL: directoryURL.appendingPathComponent("import-files", isDirectory: true)
            )
        )
        let viewModel = DataBackupImportViewModel(
            profileRepository: profileRepository,
            projectRepository: projectRepository,
            patternRepository: patternRepository,
            libraryRepository: libraryRepository,
            skillRepository: skillRepository,
            dictionaryRepository: dictionaryRepository,
            gaugeRecordRepository: gaugeRecordRepository,
            progressPhotoRepository: progressPhotoRepository
        )

        let didImport = await viewModel.importBackup(from: backupURL)

        #expect(didImport)
        #expect((try await profileRepository.fetchCurrentProfile()).id == SampleData.profile.id)
        #expect((try await projectRepository.fetchProjects()).map(\.id) == [project.id])
        #expect((try await patternRepository.fetchPatterns()).map(\.id) == [SampleData.patternDocuments[0].id])
        #expect((try await libraryRepository.fetchYarns()).map(\.id) == [yarn.id])
        #expect((try await libraryRepository.fetchNeedles()).map(\.id) == [needle.id])
        #expect((try await libraryRepository.fetchTools()).map(\.id) == [tool.id])
        #expect((try await libraryRepository.fetchYarnUsages(forProjectId: project.id)).map(\.id) == [usage.id])
        #expect((try await libraryRepository.fetchTools(forProjectId: project.id)).map(\.id) == [tool.id])
        #expect((try await skillRepository.fetchSkills()).map(\.id) == [SampleData.skills[0].id])
        #expect((try await dictionaryRepository.fetchTerms()).map(\.id) == [SampleData.dictionaryTerms[0].id])
        let restoredPhotos = try await progressPhotoRepository.fetchProgressPhotos(projectId: project.id)
        #expect(restoredPhotos.count == 1)
        #expect(restoredPhotos.first?.caption == "Restored progress")
        let restoredPhoto = try #require(restoredPhotos.first)
        let restoredPhotoURL = try #require(progressPhotoRepository.fileURL(for: restoredPhoto))
        let restoredPhotoData = try Data(contentsOf: restoredPhotoURL)
        #expect(restoredPhotoData == Data([5, 6, 7, 8]))
        #expect(viewModel.statusMessage == "백업 파일을 가져왔어요.")
        #expect(viewModel.errorMessage == nil)
    }
}
