//
//  LibraryRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol LibraryRepository {
    func fetchYarns() async throws -> [Yarn]
    func fetchNeedles() async throws -> [Needle]
}
