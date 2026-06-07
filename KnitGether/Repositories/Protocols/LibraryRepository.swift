//
//  LibraryRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol LibraryRepository {
    func fetchYarns() async throws -> [Yarn]
    func fetchYarn(id: UUID) async throws -> Yarn?
    func saveYarn(_ yarn: Yarn) async throws
    func deleteYarn(id: UUID) async throws
    func fetchNeedles() async throws -> [Needle]
}
