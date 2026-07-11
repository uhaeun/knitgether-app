//
//  RemoteGaugeRecordRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

final class RemoteGaugeRecordRepository: GaugeRecordRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchGaugeRecords() async throws -> [GaugeRecord] {
        try await apiClient.get("gauge-records")
    }

    func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        let body = SaveGaugeRecordRequest(record: record)
        return try await apiClient.send(
            "gauge-records",
            method: "POST",
            body: body
        )
    }

    func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
        let body = SaveGaugeRecordRequest(record: record)
        return try await apiClient.send(
            "gauge-records/\(record.id.uuidString.lowercased())",
            method: "PATCH",
            body: body
        )
    }

    func deleteGaugeRecord(id: UUID) async throws {
        try await apiClient.delete("gauge-records/\(id.uuidString.lowercased())")
    }
}

private struct SaveGaugeRecordRequest: Encodable {
    let id: String
    let projectId: String?
    let projectNameSnapshot: String?
    let patternNameSnapshot: String?
    let measurementStage: String
    let sampleWidthCm: Double
    let sampleHeightCm: Double
    let stitchCount: Double
    let rowCount: Double
    let targetWidthCm: Double
    let targetHeightCm: Double
    let needle: String
    let memo: String
    let measuredAt: Date

    init(record: GaugeRecord) {
        id = record.id.uuidString.lowercased()
        projectId = record.projectId?.uuidString.lowercased()
        projectNameSnapshot = record.projectNameSnapshot
        patternNameSnapshot = record.patternNameSnapshot
        measurementStage = record.measurementStage.rawValue
        sampleWidthCm = record.sampleWidthCm
        sampleHeightCm = record.sampleHeightCm
        stitchCount = record.stitchCount
        rowCount = record.rowCount
        targetWidthCm = record.targetWidthCm
        targetHeightCm = record.targetHeightCm
        needle = record.needle
        memo = record.memo
        measuredAt = record.measuredAt
    }
}
