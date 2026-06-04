//
//  ProjectRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol ProjectRepository {
    func fetchProjects() async throws -> [KnittingProject]
    func fetchProject(id: UUID) async throws -> KnittingProject?
    func saveProject(_ project: KnittingProject) async throws
}
