import Foundation
import Testing
@testable import KnitGether

@MainActor
struct OfflineFirstGaugeRecordRepositoryTests {
    @Test func fetchGaugeRecordsFallsBackToLocalCacheWhenRemoteIsOffline() async throws {
        let localRecord = Self.makeGaugeRecord(syncStatus: .synced)
        let local = LocalGaugeRecordRepository(records: [localRecord])
        let remote = GaugeRecordRepositoryFake()
        remote.fetchGaugeRecordsError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        let records = try await repository.fetchGaugeRecords()

        #expect(records.map(\.id) == [localRecord.id])
    }

    @Test func saveGaugeRecordKeepsLocalChangeAndFlushesOnNextSuccessfulFetch() async throws {
        let local = LocalGaugeRecordRepository(records: [])
        let remote = GaugeRecordRepositoryFake()
        remote.saveGaugeRecordError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)
        let record = Self.makeGaugeRecord(syncStatus: .localOnly)

        let savedRecord = try await repository.saveGaugeRecord(record)

        #expect(savedRecord.syncStatus == .localOnly)
        #expect(try await local.fetchGaugeRecords().map(\.syncStatus) == [.localOnly])
        #expect(remote.savedRecords.isEmpty)

        remote.saveGaugeRecordError = nil
        remote.remoteRecords = [record.copy(syncStatus: .synced)]

        let syncedRecords = try await repository.fetchGaugeRecords()

        #expect(remote.savedRecords.map(\.id) == [record.id])
        #expect(remote.savedRecords.map(\.syncStatus) == [.localOnly])
        #expect(syncedRecords.map(\.syncStatus) == [.synced])
    }

    @Test func savePendingGaugeRecordKeepsPendingUploadWhenRemoteIsOffline() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .pendingUpload)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        remote.saveGaugeRecordError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        let savedRecord = try await repository.saveGaugeRecord(record)

        #expect(savedRecord.syncStatus == .pendingUpload)
        #expect(try await local.fetchGaugeRecords().map(\.syncStatus) == [.pendingUpload])
    }

    @Test func updateGaugeRecordKeepsPendingUploadAndFlushesWithPatchOnNextFetch() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .synced)
        let editedRecord = record.copy(syncStatus: .pendingUpload)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        remote.updateGaugeRecordError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        let savedRecord = try await repository.updateGaugeRecord(editedRecord)

        #expect(savedRecord.syncStatus == .pendingUpload)
        #expect(try await local.fetchGaugeRecords().map(\.syncStatus) == [.pendingUpload])
        #expect(remote.updatedRecords.isEmpty)

        remote.updateGaugeRecordError = nil
        remote.remoteRecords = [editedRecord.copy(syncStatus: .synced)]

        let syncedRecords = try await repository.fetchGaugeRecords()

        #expect(remote.updatedRecords.map(\.id) == [record.id])
        #expect(remote.updatedRecords.map(\.syncStatus) == [.synced])
        #expect(remote.savedRecords.isEmpty)
        #expect(syncedRecords.map(\.syncStatus) == [.synced])
    }

    @Test func deleteGaugeRecordKeepsHiddenPendingDeleteAndFlushesOnNextFetch() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .synced)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        remote.deleteGaugeRecordError = URLError(.notConnectedToInternet)
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        try await repository.deleteGaugeRecord(id: record.id)

        #expect(try await local.fetchGaugeRecords().isEmpty)
        #expect(await local.pendingGaugeRecordsForSync().map(\.syncStatus) == [.pendingDelete])
        #expect(remote.deletedRecordIDs.isEmpty)

        remote.deleteGaugeRecordError = nil

        _ = try await repository.fetchGaugeRecords()

        #expect(remote.deletedRecordIDs == [record.id])
        #expect(await local.pendingGaugeRecordsForSync().isEmpty)
    }

    @Test func deleteLocalOnlyGaugeRecordDoesNotCallRemoteDelete() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .localOnly)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        try await repository.deleteGaugeRecord(id: record.id)

        #expect(remote.deletedRecordIDs.isEmpty)
        #expect(try await local.fetchGaugeRecords().isEmpty)
        #expect(await local.pendingGaugeRecordsForSync().isEmpty)
    }

    @Test func rejectedPendingGaugeRecordRemovesUnacceptedLocalOnlyChangeOnFetch() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .localOnly)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        remote.saveGaugeRecordError = APIError.requestFailed(
            statusCode: 400,
            code: "VALIDATION_ERROR",
            message: "Invalid gauge record."
        )
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        let records = try await repository.fetchGaugeRecords()

        #expect(records.isEmpty)
        #expect(await local.pendingGaugeRecordsForSync().isEmpty)
    }

    @Test func rejectedPendingGaugeRecordDeleteClearsTombstoneOnFetch() async throws {
        let record = Self.makeGaugeRecord(syncStatus: .pendingDelete)
        let local = LocalGaugeRecordRepository(records: [record])
        let remote = GaugeRecordRepositoryFake()
        remote.deleteGaugeRecordError = APIError.requestFailed(
            statusCode: 404,
            code: "NOT_FOUND",
            message: "Gauge record not found."
        )
        let repository = OfflineFirstGaugeRecordRepository(local: local, remote: remote)

        let records = try await repository.fetchGaugeRecords()

        #expect(records.isEmpty)
        #expect(await local.pendingGaugeRecordsForSync().isEmpty)
    }

    private static func makeGaugeRecord(
        id: UUID = UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
        syncStatus: SyncStatus
    ) -> GaugeRecord {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return GaugeRecord(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            projectNameSnapshot: "Favorite Cardigan",
            patternNameSnapshot: "Cozy Shawl",
            measurementStage: .beforeWash,
            sampleWidthCm: 10,
            sampleHeightCm: 10,
            stitchCount: 22,
            rowCount: 30,
            targetWidthCm: 40,
            targetHeightCm: 55,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            targetStitches: 88,
            targetRows: 165,
            needle: "4.0mm circular",
            memo: "Measured before blocking.",
            measuredAt: now,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }
}

@MainActor
private final class GaugeRecordRepositoryFake: GaugeRecordRepository {
    var remoteRecords: [GaugeRecord] = []
    var savedRecords: [GaugeRecord] = []
    var updatedRecords: [GaugeRecord] = []
    var deletedRecordIDs: [UUID] = []
    var fetchGaugeRecordsError: Error?
    var saveGaugeRecordError: Error?
    var updateGaugeRecordError: Error?
    var deleteGaugeRecordError: Error?

    func fetchGaugeRecords() async throws -> [GaugeRecord] {
        if let fetchGaugeRecordsError {
            throw fetchGaugeRecordsError
        }

        return remoteRecords
    }

    func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        if let saveGaugeRecordError {
            throw saveGaugeRecordError
        }

        savedRecords.append(record)
        return record.copy(syncStatus: .synced)
    }

    func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        if let updateGaugeRecordError {
            throw updateGaugeRecordError
        }

        updatedRecords.append(record)
        return record.copy(syncStatus: .synced)
    }

    func deleteGaugeRecord(id: UUID) async throws {
        if let deleteGaugeRecordError {
            throw deleteGaugeRecordError
        }

        deletedRecordIDs.append(id)
    }
}
