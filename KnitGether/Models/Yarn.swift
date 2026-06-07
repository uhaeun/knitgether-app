//
//  Yarn.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct Yarn: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerId: String?
    let name: String
    let brand: String?
    let colorName: String?
    let colorCode: String?
    let weight: String?
    let lengthMeters: Double?
    let fiberContent: String?
    let gaugeMemo: String?
    let quantity: Int?
    let memo: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncStatus: SyncStatus

    var colorway: String? {
        colorName
    }

    var notes: String {
        memo ?? ""
    }

    init(
        id: UUID = UUID(),
        ownerId: String? = nil,
        name: String,
        brand: String? = nil,
        colorName: String? = nil,
        colorCode: String? = nil,
        weight: String? = nil,
        lengthMeters: Double? = nil,
        fiberContent: String? = nil,
        gaugeMemo: String? = nil,
        quantity: Int? = nil,
        memo: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.brand = brand
        self.colorName = colorName
        self.colorCode = colorCode
        self.weight = weight
        self.lengthMeters = lengthMeters
        self.fiberContent = fiberContent
        self.gaugeMemo = gaugeMemo
        self.quantity = quantity
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatus = syncStatus
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case name
        case brand
        case colorName
        case colorCode
        case colorway
        case weight
        case lengthMeters
        case fiberContent
        case gaugeMemo
        case quantity
        case memo
        case notes
        case createdAt
        case updatedAt
        case deletedAt
        case syncStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName)
            ?? container.decodeIfPresent(String.self, forKey: .colorway)
        colorCode = try container.decodeIfPresent(String.self, forKey: .colorCode)
        weight = try container.decodeIfPresent(String.self, forKey: .weight)
        lengthMeters = try container.decodeIfPresent(Double.self, forKey: .lengthMeters)
        fiberContent = try container.decodeIfPresent(String.self, forKey: .fiberContent)
        gaugeMemo = try container.decodeIfPresent(String.self, forKey: .gaugeMemo)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
            ?? container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .localOnly
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(colorName, forKey: .colorName)
        try container.encodeIfPresent(colorCode, forKey: .colorCode)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(lengthMeters, forKey: .lengthMeters)
        try container.encodeIfPresent(fiberContent, forKey: .fiberContent)
        try container.encodeIfPresent(gaugeMemo, forKey: .gaugeMemo)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(memo, forKey: .memo)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(syncStatus, forKey: .syncStatus)
    }
}
