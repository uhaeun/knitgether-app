//
//  ProjectProgressPhotoRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

protocol ProjectProgressPhotoRepository {
    func fetchProgressPhotos(projectId: UUID) async throws -> [ProjectProgressPhoto]
    func createProgressPhoto(
        projectId: UUID,
        imageData: Data,
        fileName: String,
        contentType: String,
        caption: String,
        takenAt: Date
    ) async throws -> ProjectProgressPhoto
    func updateProgressPhoto(
        _ photo: ProjectProgressPhoto,
        caption: String,
        takenAt: Date
    ) async throws -> ProjectProgressPhoto
    func deleteProgressPhoto(_ photo: ProjectProgressPhoto) async throws
    func fileURL(for photo: ProjectProgressPhoto) -> URL?
}
