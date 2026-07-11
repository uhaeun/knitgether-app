//
//  LibraryRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol LibraryRepository {
    func fetchYarns() async throws -> [Yarn]
    func saveYarn(_ yarn: Yarn) async throws
    func deleteYarn(id: UUID) async throws
    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage]
    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage]
    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage
    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage
    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws
    func fetchNeedles() async throws -> [Needle]
    func saveNeedle(_ needle: Needle) async throws
    func deleteNeedle(id: UUID) async throws
    func fetchTools() async throws -> [ToolItem]
    func saveTool(_ tool: ToolItem) async throws
    func deleteTool(id: UUID) async throws
    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem]
    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem
    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws
}
