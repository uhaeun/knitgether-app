//
//  GaugeRecordRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

protocol GaugeRecordRepository {
    func fetchGaugeRecords() async throws -> [GaugeRecord]
    func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord
    func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord
    func deleteGaugeRecord(id: UUID) async throws
}
