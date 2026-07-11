import Foundation
import Testing
@testable import KnitGether

@MainActor
struct LocalRepositoryPersistenceTests {
    @Test func projectRepositoryCanLoadDiskCacheWithoutSeedingSamples() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let fileURL = tempDirectory.appendingPathComponent("projects.json")
        let project = Self.makeProject(syncStatus: .synced)
        let writer = LocalProjectRepository(
            projects: [],
            fileURL: fileURL
        )

        #expect(try await writer.fetchProjects().isEmpty)

        try await writer.saveProject(project)

        let reader = LocalProjectRepository(
            seedSamples: false,
            fileURL: fileURL
        )
        let projects = try await reader.fetchProjects()

        #expect(projects.map(\.id) == [project.id])
        #expect(projects.map(\.syncStatus) == [.synced])
    }

    @Test func patternRepositoryCanStartEmptyWithoutSeedingSamples() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let repository = LocalPatternRepository(
            seedSamples: false,
            fileURL: tempDirectory.appendingPathComponent("patterns.json"),
            fileStore: LocalPatternFileStore(
                rootDirectoryURL: tempDirectory.appendingPathComponent("files", isDirectory: true)
            )
        )

        let patterns = try await repository.fetchPatterns()

        #expect(patterns.isEmpty)
    }

    @Test func skillRepositoryCanLoadDiskCacheWithoutSeedingSamples() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let fileURL = tempDirectory.appendingPathComponent("skills.json")
        let skill = Self.makeSkill(syncStatus: .synced)
        let writer = LocalSkillRepository(
            skills: [],
            animations: [],
            fileURL: fileURL
        )

        #expect(try await writer.fetchSkills().isEmpty)

        try await writer.saveSkill(skill)

        let reader = LocalSkillRepository(
            animations: [],
            seedSamples: false,
            fileURL: fileURL
        )
        let skills = try await reader.fetchSkills()

        #expect(skills.map(\.id) == [skill.id])
        #expect(skills.map(\.syncStatus) == [.synced])
    }

    @Test func libraryRepositoryCanLoadDiskCacheWithoutSeedingSamples() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let fileURL = tempDirectory.appendingPathComponent("library.json")
        let yarn = Self.makeYarn(syncStatus: .synced)
        let needle = Self.makeNeedle(syncStatus: .synced)
        let tool = Self.makeTool(syncStatus: .synced)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, syncStatus: .synced)
        let writer = LocalLibraryRepository(
            yarns: [],
            needles: [],
            yarnUsages: [],
            tools: [],
            fileURL: fileURL
        )

        #expect(try await writer.fetchYarns().isEmpty)
        #expect(try await writer.fetchNeedles().isEmpty)
        #expect(try await writer.fetchTools().isEmpty)

        try await writer.saveYarn(yarn)
        try await writer.saveNeedle(needle)
        try await writer.saveTool(tool)
        _ = try await writer.linkTool(tool, toProjectId: usage.projectId)
        _ = try await writer.recordYarnUsage(usage)

        let reader = LocalLibraryRepository(
            seedSamples: false,
            fileURL: fileURL
        )

        #expect(try await reader.fetchYarns().map(\.id) == [yarn.id])
        #expect(try await reader.fetchNeedles().map(\.id) == [needle.id])
        #expect(try await reader.fetchTools().map(\.id) == [tool.id])
        #expect(try await reader.fetchTools(forProjectId: usage.projectId).map(\.id) == [tool.id])
        #expect(try await reader.fetchYarnUsages(forProjectId: usage.projectId).map(\.id) == [usage.id])
    }

    @Test func libraryRepositoryCanStartEmptyWithoutSeedingSamples() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let repository = LocalLibraryRepository(
            seedSamples: false,
            fileURL: tempDirectory.appendingPathComponent("library.json")
        )

        #expect(try await repository.fetchYarns().isEmpty)
        #expect(try await repository.fetchNeedles().isEmpty)
        #expect(try await repository.fetchTools().isEmpty)
    }

    @Test func profileRepositoryCanLoadDiskCacheWithoutSeedingSample() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let fileURL = tempDirectory.appendingPathComponent("profile.json")
        let profile = Self.makeProfile(syncStatus: .synced)
        let writer = LocalProfileRepository(
            seedSample: false,
            fileURL: fileURL
        )

        do {
            _ = try await writer.fetchCurrentProfile()
            Issue.record("Expected profileNotFound before saving profile cache.")
        } catch LocalProfileRepositoryError.profileNotFound {
        }

        try await writer.saveCurrentProfile(profile)

        let reader = LocalProfileRepository(
            seedSample: false,
            fileURL: fileURL
        )
        let cachedProfile = try await reader.fetchCurrentProfile()

        #expect(cachedProfile.id == profile.id)
        #expect(cachedProfile.displayName == "Local Knitter")
        #expect(cachedProfile.syncStatus == .synced)
    }

    private static func makeProject(syncStatus: SyncStatus) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        let projectId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        return KnittingProject(
            id: projectId,
            ownerId: "user-a",
            name: "Cached Cardigan",
            status: .wip,
            isFavorite: false,
            memo: "",
            startDate: now,
            lastWorkedAt: nil,
            patternCopy: nil,
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: projectId,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now,
                syncStatus: syncStatus
            ),
            workSessions: [],
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func makeSkill(syncStatus: SyncStatus) -> Skill {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Skill(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            ownerId: "user-a",
            name: "Knit",
            abbreviation: "K",
            description: "Knit stitch.",
            category: "Basics",
            difficulty: "New",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func makeYarn(syncStatus: SyncStatus) -> Yarn {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Yarn(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            ownerId: "user-a",
            name: "Soft Merino DK",
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: 5,
            notes: "Cached yarn.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeNeedle(syncStatus: SyncStatus) -> Needle {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return Needle(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            ownerId: "user-a",
            name: "Wood Circular Needle",
            needleType: "Circular",
            size: "5.0 mm",
            length: "80 cm",
            notes: "Cached needle.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeTool(syncStatus: SyncStatus) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return ToolItem(
            id: UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
            ownerId: "user-a",
            name: "Locking Marker Set",
            type: "Marker",
            link: "example.com/marker",
            memo: "Raglan increases.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeYarnUsage(
        yarnId: UUID,
        syncStatus: SyncStatus
    ) -> ProjectYarnUsage {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return ProjectYarnUsage(
            id: UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            projectNameSnapshot: "Cached Cardigan",
            yarnId: yarnId,
            yarnNameSnapshot: "Soft Merino DK",
            quantityUsed: 2,
            memo: "Cached usage.",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeProfile(syncStatus: SyncStatus) -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: "user-a",
            ownerId: "user-a",
            displayName: "Local Knitter",
            preferredUnits: "Metric",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalRepositoryPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
