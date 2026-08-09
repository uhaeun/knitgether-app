import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstLibraryRepositoryTests {
    @Test func fetchYarnsFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let localYarn = Self.makeYarn(syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [localYarn], needles: [])
        let remote = LibraryRepositoryFake()
        remote.fetchYarnsError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        let yarns = try await repository.fetchYarns()

        #expect(yarns == [localYarn])
    }

    @Test func saveYarnKeepsLocalChangeAndFlushesOnNextSuccessfulFetch() async throws {
        let local = LocalLibraryRepository(yarns: [], needles: [])
        let remote = LibraryRepositoryFake()
        remote.saveYarnError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)
        let yarn = Self.makeYarn(syncStatus: .localOnly)

        try await repository.saveYarn(yarn)

        #expect(try await local.fetchYarns().map(\.syncStatus) == [.localOnly])
        #expect(remote.savedYarns.isEmpty)

        remote.saveYarnError = nil
        remote.remoteYarns = [Self.makeYarn(syncStatus: .synced)]

        let syncedYarns = try await repository.fetchYarns()

        #expect(remote.savedYarns.map(\.id) == [yarn.id])
        #expect(syncedYarns.map(\.syncStatus) == [.synced])
    }

    @Test func savePendingYarnUploadsAsExistingYarnWhenRemoteIsAvailable() async throws {
        let yarn = Self.makeYarn(syncStatus: .pendingUpload)
        let local = LocalLibraryRepository(yarns: [yarn], needles: [])
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.saveYarn(yarn)

        #expect(remote.savedYarns.map(\.id) == [yarn.id])
        #expect(remote.savedYarns.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchYarns().map(\.syncStatus) == [.synced])
    }

    @Test func saveYarnCachesServerVersionAfterSuccessfulUpload() async throws {
        let yarn = Self.makeYarn(name: "Local Yarn", syncStatus: .localOnly)
        let serverYarn = Self.makeYarn(name: "Server Yarn", syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [], needles: [])
        let remote = LibraryRepositoryFake()
        remote.remoteYarns = [serverYarn]
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.saveYarn(yarn)

        let cachedYarn = try #require(await local.fetchYarns().first { $0.id == yarn.id })
        #expect(cachedYarn.name == "Server Yarn")
        #expect(cachedYarn.syncStatus == .synced)
    }

    @Test func savePendingNeedleUploadsAsExistingNeedleWhenRemoteIsAvailable() async throws {
        let needle = Self.makeNeedle(syncStatus: .pendingUpload)
        let local = LocalLibraryRepository(yarns: [], needles: [needle])
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.saveNeedle(needle)

        #expect(remote.savedNeedles.map(\.id) == [needle.id])
        #expect(remote.savedNeedles.map(\.syncStatus) == [.synced])
        #expect(try await local.fetchNeedles().map(\.syncStatus) == [.synced])
    }

    @Test func saveNeedleCachesServerVersionAfterSuccessfulUpload() async throws {
        let needle = Self.makeNeedle(name: "Local Needle", syncStatus: .localOnly)
        let serverNeedle = Self.makeNeedle(name: "Server Needle", syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [], needles: [])
        let remote = LibraryRepositoryFake()
        remote.remoteNeedles = [serverNeedle]
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.saveNeedle(needle)

        let cachedNeedle = try #require(await local.fetchNeedles().first { $0.id == needle.id })
        #expect(cachedNeedle.name == "Server Needle")
        #expect(cachedNeedle.syncStatus == .synced)
    }

    @Test func saveToolKeepsLocalChangeAndFlushesOnNextSuccessfulFetch() async throws {
        let local = LocalLibraryRepository(yarns: [], needles: [], tools: [])
        let remote = LibraryRepositoryFake()
        remote.saveToolError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)
        let tool = Self.makeTool(syncStatus: .localOnly)

        try await repository.saveTool(tool)

        #expect(try await local.fetchTools().map(\.syncStatus) == [.localOnly])
        #expect(remote.savedTools.isEmpty)

        remote.saveToolError = nil
        remote.remoteTools = [Self.makeTool(syncStatus: .synced)]

        let syncedTools = try await repository.fetchTools()

        #expect(remote.savedTools.map(\.id) == [tool.id])
        #expect(syncedTools.map(\.syncStatus) == [.synced])
    }

    @Test func saveToolCachesServerVersionAfterSuccessfulUpload() async throws {
        let tool = Self.makeTool(name: "Local Marker", syncStatus: .localOnly)
        let serverTool = Self.makeTool(name: "Server Marker", syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [], needles: [], tools: [])
        let remote = LibraryRepositoryFake()
        remote.remoteTools = [serverTool]
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.saveTool(tool)

        let cachedTool = try #require(await local.fetchTools().first { $0.id == tool.id })
        #expect(cachedTool.name == "Server Marker")
        #expect(cachedTool.syncStatus == .synced)
    }

    @Test func deleteLocalOnlyYarnDoesNotCallRemoteDelete() async throws {
        let yarn = Self.makeYarn(syncStatus: .localOnly)
        let local = LocalLibraryRepository(yarns: [yarn], needles: [])
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.deleteYarn(id: yarn.id)

        #expect(remote.deletedYarnIDs.isEmpty)
        #expect(try await local.fetchYarns().isEmpty)
        #expect(await local.pendingYarnsForSync().isEmpty)
    }

    @Test func deleteLocalOnlyNeedleDoesNotCallRemoteDelete() async throws {
        let needle = Self.makeNeedle(syncStatus: .localOnly)
        let local = LocalLibraryRepository(yarns: [], needles: [needle])
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.deleteNeedle(id: needle.id)

        #expect(remote.deletedNeedleIDs.isEmpty)
        #expect(try await local.fetchNeedles().isEmpty)
        #expect(await local.pendingNeedlesForSync().isEmpty)
    }

    @Test func deleteLocalOnlyToolDoesNotCallRemoteDelete() async throws {
        let tool = Self.makeTool(syncStatus: .localOnly)
        let local = LocalLibraryRepository(yarns: [], needles: [], tools: [tool])
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.deleteTool(id: tool.id)

        #expect(remote.deletedToolIDs.isEmpty)
        #expect(try await local.fetchTools().isEmpty)
        #expect(await local.pendingToolsForSync().isEmpty)
    }

    @Test func recordYarnUsageKeepsLocalChangeAndFlushesOnNextUsageFetch() async throws {
        let yarn = Self.makeYarn(quantity: 5, syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [yarn], needles: [])
        let remote = LibraryRepositoryFake()
        remote.recordYarnUsageError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, syncStatus: .localOnly)

        let savedUsage = try await repository.recordYarnUsage(usage)

        #expect(savedUsage.syncStatus == .localOnly)
        #expect(try await local.fetchYarnUsages(forProjectId: usage.projectId).map(\.syncStatus) == [.localOnly])
        #expect(try await local.fetchYarns().first?.quantity == 3)
        #expect(remote.recordedYarnUsages.isEmpty)

        remote.recordYarnUsageError = nil
        remote.remoteYarnUsages = [Self.makeYarnUsage(yarnId: yarn.id, syncStatus: .synced)]

        let syncedUsages = try await repository.fetchYarnUsages(forProjectId: usage.projectId)

        #expect(remote.recordedYarnUsages.map(\.id) == [usage.id])
        #expect(syncedUsages.map(\.syncStatus) == [.synced])
    }

    @Test func recordYarnUsageRollsBackInventoryWhenRemoteRejectsChange() async throws {
        let yarn = Self.makeYarn(quantity: 5, syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [yarn], needles: [])
        let remote = LibraryRepositoryFake()
        remote.recordYarnUsageError = APIError.requestFailed(
            statusCode: 400,
            code: "INSUFFICIENT_YARN",
            message: "Quantity cannot be reserved."
        )
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, syncStatus: .localOnly)

        do {
            _ = try await repository.recordYarnUsage(usage)
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 400)
        }

        #expect(try await local.fetchYarns().first?.quantity == 5)
        #expect(try await local.fetchYarnUsages(forProjectId: usage.projectId).isEmpty)
        #expect(await local.pendingYarnUsagesForSync().isEmpty)
    }

    @Test func saveYarnRollsBackLocalChangeWhenRemoteRejectsChange() async throws {
        let local = LocalLibraryRepository(yarns: [], needles: [])
        let remote = LibraryRepositoryFake()
        remote.saveYarnError = APIError.requestFailed(
            statusCode: 404,
            code: "OWNER_NOT_FOUND",
            message: "Owner does not exist."
        )
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)
        let yarn = Self.makeYarn(syncStatus: .localOnly)

        do {
            try await repository.saveYarn(yarn)
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 404)
        }

        #expect(try await local.fetchYarns().isEmpty)
        #expect(await local.pendingYarnsForSync().isEmpty)
    }

    @Test func deleteYarnRollsBackLocalDeletionWhenRemoteRejectsChange() async throws {
        let yarn = Self.makeYarn(quantity: 5, syncStatus: .synced)
        let local = LocalLibraryRepository(yarns: [yarn], needles: [])
        let remote = LibraryRepositoryFake()
        remote.deleteYarnError = APIError.requestFailed(
            statusCode: 404,
            code: "YARN_NOT_FOUND",
            message: "Yarn does not exist."
        )
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        do {
            try await repository.deleteYarn(id: yarn.id)
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 404)
        }

        let cachedYarn = try #require(await local.fetchYarns().first)
        #expect(cachedYarn.id == yarn.id)
        #expect(cachedYarn.syncStatus == .synced)
        #expect(await local.pendingYarnsForSync().isEmpty)
    }

    @Test func deleteLocalOnlyYarnUsageDoesNotCallRemoteDelete() async throws {
        let yarn = Self.makeYarn(quantity: 3, syncStatus: .synced)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, syncStatus: .localOnly)
        let local = LocalLibraryRepository(
            yarns: [yarn],
            needles: [],
            yarnUsages: [usage]
        )
        let remote = LibraryRepositoryFake()
        let repository = OfflineFirstLibraryRepository(local: local, remote: remote)

        try await repository.deleteYarnUsage(usage)

        #expect(remote.deletedYarnUsageIDs.isEmpty)
        #expect(try await local.fetchYarnUsages(forProjectId: usage.projectId).isEmpty)
        #expect(await local.pendingYarnUsagesForSync().isEmpty)
    }

    private static func makeYarn(
        id: UUID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
        name: String = "Soft Merino DK",
        quantity: Int = 5,
        syncStatus: SyncStatus
    ) -> Yarn {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return Yarn(
            id: id,
            ownerId: "user-a",
            name: name,
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: quantity,
            notes: "Reserved for cardigan.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeNeedle(
        id: UUID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
        name: String = "Wood Circular Needle",
        syncStatus: SyncStatus
    ) -> Needle {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return Needle(
            id: id,
            ownerId: "user-a",
            name: name,
            needleType: "Circular",
            size: "5.0 mm",
            length: "80 cm",
            notes: "Cardigan body.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeYarnUsage(
        id: UUID = UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
        yarnId: UUID,
        syncStatus: SyncStatus
    ) -> ProjectYarnUsage {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ProjectYarnUsage(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            projectNameSnapshot: "Favorite Cardigan",
            yarnId: yarnId,
            yarnNameSnapshot: "Soft Merino DK",
            quantityUsed: 2,
            memo: "Sleeve swatch",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeTool(
        id: UUID = UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
        name: String = "Locking Marker Set",
        syncStatus: SyncStatus
    ) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ToolItem(
            id: id,
            ownerId: "user-a",
            name: name,
            type: "Marker",
            link: "example.com/marker",
            memo: "Raglan increases.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }
}

@MainActor
private final class LibraryRepositoryFake: LibraryRepository {
    var remoteYarns: [Yarn] = []
    var remoteNeedles: [Needle] = []
    var remoteTools: [ToolItem] = []
    var remoteYarnUsages: [ProjectYarnUsage] = []
    var remoteProjectToolsByProjectID: [UUID: [ToolItem]] = [:]
    var savedYarns: [Yarn] = []
    var savedNeedles: [Needle] = []
    var savedTools: [ToolItem] = []
    var recordedYarnUsages: [ProjectYarnUsage] = []
    var updatedYarnUsages: [ProjectYarnUsage] = []
    var deletedYarnIDs: [UUID] = []
    var deletedNeedleIDs: [UUID] = []
    var deletedToolIDs: [UUID] = []
    var deletedYarnUsageIDs: [UUID] = []
    var linkedToolIDsByProjectID: [UUID: [UUID]] = [:]
    var unlinkedToolIDsByProjectID: [UUID: [UUID]] = [:]
    var fetchYarnsError: Error?
    var saveYarnError: Error?
    var deleteYarnError: Error?
    var saveToolError: Error?
    var recordYarnUsageError: Error?

    func fetchYarns() async throws -> [Yarn] {
        if let fetchYarnsError {
            throw fetchYarnsError
        }

        return remoteYarns
    }

    func saveYarn(_ yarn: Yarn) async throws {
        if let saveYarnError {
            throw saveYarnError
        }

        savedYarns.append(yarn)
    }

    func deleteYarn(id: UUID) async throws {
        if let deleteYarnError {
            throw deleteYarnError
        }

        deletedYarnIDs.append(id)
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        remoteYarnUsages.filter { $0.projectId == projectId }
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        remoteYarnUsages.filter { $0.yarnId == yarnId }
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        if let recordYarnUsageError {
            throw recordYarnUsageError
        }

        recordedYarnUsages.append(usage)
        return usage.copy(syncStatus: .synced)
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        updatedYarnUsages.append(usage)
        return usage.copy(syncStatus: .synced)
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
        deletedYarnUsageIDs.append(usage.id)
    }

    func fetchNeedles() async throws -> [Needle] {
        remoteNeedles
    }

    func saveNeedle(_ needle: Needle) async throws {
        savedNeedles.append(needle)
    }

    func deleteNeedle(id: UUID) async throws {
        deletedNeedleIDs.append(id)
    }

    func fetchTools() async throws -> [ToolItem] {
        remoteTools
    }

    func saveTool(_ tool: ToolItem) async throws {
        if let saveToolError {
            throw saveToolError
        }

        savedTools.append(tool)
    }

    func deleteTool(id: UUID) async throws {
        deletedToolIDs.append(id)
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        remoteProjectToolsByProjectID[projectId] ?? []
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        linkedToolIDsByProjectID[projectId, default: []].append(tool.id)
        return tool
    }

    func fetchYarnLinks(forProjectId projectId: UUID) async throws -> [ProjectYarnLink] {
        return []
    }

    func linkYarn(_ yarn: Yarn, toProjectId projectId: UUID) async throws -> ProjectYarnLink {
        fatalError("Not needed in this test")
    }

    func unlinkYarn(yarnId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func fetchNeedleLinks(forProjectId projectId: UUID) async throws -> [ProjectNeedleLink] {
        return []
    }

    func linkNeedle(_ needle: Needle, toProjectId projectId: UUID) async throws -> ProjectNeedleLink {
        fatalError("Not needed in this test")
    }

    func unlinkNeedle(needleId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
        unlinkedToolIDsByProjectID[projectId, default: []].append(tool.id)
    }
}
