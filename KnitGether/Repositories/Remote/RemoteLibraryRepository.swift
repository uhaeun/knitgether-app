//
//  RemoteLibraryRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

final class RemoteLibraryRepository: LibraryRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchYarns() async throws -> [Yarn] {
        try await apiClient.get("library/yarns")
    }

    func saveYarn(_ yarn: Yarn) async throws {
        let body = SaveYarnRequest(yarn: yarn)

        if yarn.syncStatus == .synced {
            let _: Yarn = try await apiClient.send(
                "library/yarns/\(yarn.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: Yarn = try await apiClient.send(
                "library/yarns",
                method: "POST",
                body: body
            )
        }
    }

    func deleteYarn(id: UUID) async throws {
        try await apiClient.delete("library/yarns/\(id.uuidString.lowercased())")
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        try await apiClient.get("projects/\(projectId.uuidString.lowercased())/yarn-usages")
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        try await apiClient.get("library/yarns/\(yarnId.uuidString.lowercased())/usages")
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        try await apiClient.send(
            "projects/\(usage.projectId.uuidString.lowercased())/yarn-usages",
            method: "POST",
            body: SaveProjectYarnUsageRequest(usage: usage)
        )
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        try await apiClient.send(
            "projects/\(usage.projectId.uuidString.lowercased())/yarn-usages/\(usage.id.uuidString.lowercased())",
            method: "PATCH",
            body: SaveProjectYarnUsageRequest(usage: usage)
        )
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
        try await apiClient.delete(
            "projects/\(usage.projectId.uuidString.lowercased())/yarn-usages/\(usage.id.uuidString.lowercased())"
        )
    }

    func fetchNeedles() async throws -> [Needle] {
        try await apiClient.get("library/needles")
    }

    func saveNeedle(_ needle: Needle) async throws {
        let body = SaveNeedleRequest(needle: needle)

        if needle.syncStatus == .synced {
            let _: Needle = try await apiClient.send(
                "library/needles/\(needle.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: Needle = try await apiClient.send(
                "library/needles",
                method: "POST",
                body: body
            )
        }
    }

    func deleteNeedle(id: UUID) async throws {
        try await apiClient.delete("library/needles/\(id.uuidString.lowercased())")
    }

    func fetchTools() async throws -> [ToolItem] {
        try await apiClient.get("library/tools")
    }

    func saveTool(_ tool: ToolItem) async throws {
        let body = SaveToolRequest(tool: tool)

        if tool.syncStatus == .synced {
            let _: ToolItem = try await apiClient.send(
                "library/tools/\(tool.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: ToolItem = try await apiClient.send(
                "library/tools",
                method: "POST",
                body: body
            )
        }
    }

    func deleteTool(id: UUID) async throws {
        try await apiClient.delete("library/tools/\(id.uuidString.lowercased())")
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        try await apiClient.get("library/projects/\(projectId.uuidString.lowercased())/tools")
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        try await apiClient.send(
            "library/projects/\(projectId.uuidString.lowercased())/tools/\(tool.id.uuidString.lowercased())",
            method: "POST",
            body: EmptyRequest()
        )
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
        try await apiClient.delete(
            "library/projects/\(projectId.uuidString.lowercased())/tools/\(tool.id.uuidString.lowercased())"
        )
    }

    func fetchYarnLinks(forProjectId projectId: UUID) async throws -> [ProjectYarnLink] {
        try await apiClient.get("library/projects/\(projectId.uuidString.lowercased())/yarn-links")
    }

    func linkYarn(_ yarn: Yarn, toProjectId projectId: UUID) async throws -> ProjectYarnLink {
        try await apiClient.send(
            "library/projects/\(projectId.uuidString.lowercased())/yarns/\(yarn.id.uuidString.lowercased())",
            method: "POST",
            body: EmptyRequest()
        )
    }

    func unlinkYarn(yarnId: UUID, fromProjectId projectId: UUID) async throws {
        try await apiClient.delete(
            "library/projects/\(projectId.uuidString.lowercased())/yarns/\(yarnId.uuidString.lowercased())"
        )
    }

    func fetchNeedleLinks(forProjectId projectId: UUID) async throws -> [ProjectNeedleLink] {
        try await apiClient.get("library/projects/\(projectId.uuidString.lowercased())/needle-links")
    }

    func linkNeedle(_ needle: Needle, toProjectId projectId: UUID) async throws -> ProjectNeedleLink {
        try await apiClient.send(
            "library/projects/\(projectId.uuidString.lowercased())/needles/\(needle.id.uuidString.lowercased())",
            method: "POST",
            body: EmptyRequest()
        )
    }

    func unlinkNeedle(needleId: UUID, fromProjectId projectId: UUID) async throws {
        try await apiClient.delete(
            "library/projects/\(projectId.uuidString.lowercased())/needles/\(needleId.uuidString.lowercased())"
        )
    }
}

private struct SaveYarnRequest: Encodable {
    let id: String
    let name: String
    let brand: String?
    let colorway: String?
    let weight: String?
    let quantity: Int
    let notes: String

    init(yarn: Yarn) {
        id = yarn.id.uuidString.lowercased()
        name = yarn.name
        brand = yarn.brand
        colorway = yarn.colorway
        weight = yarn.weight
        quantity = yarn.quantity
        notes = yarn.notes
    }
}

private struct SaveNeedleRequest: Encodable {
    let id: String
    let name: String
    let needleType: String
    let size: String
    let length: String?
    let notes: String

    init(needle: Needle) {
        id = needle.id.uuidString.lowercased()
        name = needle.name
        needleType = needle.needleType
        size = needle.size
        length = needle.length
        notes = needle.notes
    }
}

private struct SaveToolRequest: Encodable {
    let id: String
    let name: String
    let type: String
    let link: String?
    let memo: String

    init(tool: ToolItem) {
        id = tool.id.uuidString.lowercased()
        name = tool.name
        type = tool.type
        link = tool.link
        memo = tool.memo
    }
}

private struct EmptyRequest: Encodable {}

private struct SaveProjectYarnUsageRequest: Encodable {
    let id: String
    let yarnId: String
    let yarnNameSnapshot: String
    let quantityUsed: Int
    let memo: String
    let usedAt: Date

    init(usage: ProjectYarnUsage) {
        id = usage.id.uuidString.lowercased()
        yarnId = usage.yarnId.uuidString.lowercased()
        yarnNameSnapshot = usage.yarnNameSnapshot
        quantityUsed = usage.quantityUsed
        memo = usage.memo
        usedAt = usage.usedAt
    }
}
