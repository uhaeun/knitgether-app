//
//  RowCounter.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct RowCounter: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let projectId: UUID
    let name: String
    let mode: RowCounterMode
    let sectionName: String?
    let memo: String?
    let currentRow: Int
    let targetRow: Int?
    let rowInstructions: [RowInstruction]
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        projectId: UUID,
        name: String = "Main Counter",
        mode: RowCounterMode = .simple,
        sectionName: String? = nil,
        memo: String? = nil,
        currentRow: Int,
        targetRow: Int?,
        rowInstructions: [RowInstruction] = [],
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.projectId = projectId
        self.name = name
        self.mode = mode
        self.sectionName = sectionName
        self.memo = memo
        self.currentRow = currentRow
        self.targetRow = targetRow
        self.rowInstructions = rowInstructions.sorted { first, second in
            if first.rowNumber == second.rowNumber {
                return first.instructionText.localizedStandardCompare(second.instructionText) == .orderedAscending
            }
            return first.rowNumber < second.rowNumber
        }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    func copy(
        name: String? = nil,
        mode: RowCounterMode? = nil,
        sectionName: String? = nil,
        memo: String? = nil,
        currentRow: Int? = nil,
        targetRow: Int? = nil,
        rowInstructions: [RowInstruction]? = nil,
        updatedAt: Date = Date()
    ) -> RowCounter {
        RowCounter(
            id: id,
            ownerId: ownerId,
            projectId: projectId,
            name: name ?? self.name,
            mode: mode ?? self.mode,
            sectionName: sectionName ?? self.sectionName,
            memo: memo ?? self.memo,
            currentRow: currentRow ?? self.currentRow,
            targetRow: targetRow ?? self.targetRow,
            rowInstructions: rowInstructions ?? self.rowInstructions,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case projectId
        case name
        case mode
        case sectionName
        case memo
        case currentRow
        case targetRow
        case rowInstructions
        case createdAt
        case updatedAt
        case deletedAt
        case syncStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
        projectId = try container.decode(UUID.self, forKey: .projectId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Main Counter"
        mode = try container.decodeIfPresent(RowCounterMode.self, forKey: .mode) ?? .simple
        sectionName = try container.decodeIfPresent(String.self, forKey: .sectionName)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        currentRow = try container.decode(Int.self, forKey: .currentRow)
        targetRow = try container.decodeIfPresent(Int.self, forKey: .targetRow)
        rowInstructions = try container.decodeIfPresent([RowInstruction].self, forKey: .rowInstructions) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .localOnly
    }
}
