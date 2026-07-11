//
//  LocalProjectProgressPhotoRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

@MainActor
final class LocalProjectProgressPhotoRepository: ProjectProgressPhotoRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private let fileStore: LocalProjectProgressPhotoFileStore
    private var photos: [ProjectProgressPhoto]

    init(
        photos: [ProjectProgressPhoto]? = nil,
        fileManager: FileManager = .default,
        fileURL: URL? = nil,
        fileStore: LocalProjectProgressPhotoFileStore? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.fileStore = fileStore ?? LocalProjectProgressPhotoFileStore()

        if let photos {
            self.photos = photos
        } else {
            self.photos = Self.loadPhotos(fileURL: self.fileURL, fileManager: fileManager)
        }
    }

    func fetchProgressPhotos(projectId: UUID) async throws -> [ProjectProgressPhoto] {
        photos
            .filter { $0.projectId == projectId && $0.deletedAt == nil }
            .sorted { first, second in
                if first.takenAt == second.takenAt {
                    return first.id.uuidString < second.id.uuidString
                }
                return first.takenAt > second.takenAt
            }
    }

    func createProgressPhoto(
        projectId: UUID,
        imageData: Data,
        fileName: String,
        contentType: String,
        caption: String,
        takenAt: Date
    ) async throws -> ProjectProgressPhoto {
        let photoId = UUID()
        let storedFile = try fileStore.storePhotoData(
            imageData,
            fileName: fileName,
            projectId: projectId,
            photoId: photoId
        )
        let now = Date()
        let photo = ProjectProgressPhoto(
            id: photoId,
            ownerId: SampleData.ownerId,
            projectId: projectId,
            fileName: storedFile.fileName,
            contentType: contentType,
            byteSize: imageData.count,
            localFilePath: storedFile.relativePath,
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            takenAt: takenAt,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )

        photos.append(photo)
        try persistPhotos()
        return photo
    }

    func updateProgressPhoto(
        _ photo: ProjectProgressPhoto,
        caption: String,
        takenAt: Date
    ) async throws -> ProjectProgressPhoto {
        let updatedPhoto = ProjectProgressPhoto(
            id: photo.id,
            ownerId: photo.ownerId,
            projectId: photo.projectId,
            fileName: photo.fileName,
            contentType: photo.contentType,
            byteSize: photo.byteSize,
            localFilePath: photo.localFilePath,
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            takenAt: takenAt,
            createdAt: photo.createdAt,
            updatedAt: Date(),
            deletedAt: photo.deletedAt,
            syncStatus: photo.syncStatus == .synced ? .pendingUpload : photo.syncStatus
        )

        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
            photos[index] = updatedPhoto
        } else {
            photos.append(updatedPhoto)
        }

        try persistPhotos()
        return updatedPhoto
    }

    func deleteProgressPhoto(_ photo: ProjectProgressPhoto) async throws {
        try fileStore.removeFile(at: photo.localFilePath)
        photos.removeAll { $0.id == photo.id }
        try persistPhotos()
    }

    func fileURL(for photo: ProjectProgressPhoto) -> URL? {
        fileStore.fileURL(for: photo.localFilePath)
    }

    func cacheSyncedPhotos(_ remotePhotos: [ProjectProgressPhoto]) async throws {
        for remotePhoto in remotePhotos {
            if let index = photos.firstIndex(where: { $0.id == remotePhoto.id }) {
                photos[index] = remotePhoto
            } else {
                photos.append(remotePhoto)
            }
        }

        try persistPhotos()
    }

    func data(for photo: ProjectProgressPhoto) throws -> Data? {
        try fileStore.data(for: photo.localFilePath)
    }

    private func persistPhotos() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(photos)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadPhotos(
        fileURL: URL,
        fileManager: FileManager
    ) -> [ProjectProgressPhoto] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ProjectProgressPhoto].self, from: data)
        } catch {
            return []
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("progress-photos.json")
    }
}
