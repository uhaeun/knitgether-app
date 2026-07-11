//
//  RemoteProjectProgressPhotoRepository.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

final class RemoteProjectProgressPhotoRepository: ProjectProgressPhotoRepository {
    private let apiClient: APIClient
    private let fileStore: LocalProjectProgressPhotoFileStore

    init(
        apiClient: APIClient,
        fileStore: LocalProjectProgressPhotoFileStore
    ) {
        self.apiClient = apiClient
        self.fileStore = fileStore
    }

    func fetchProgressPhotos(projectId: UUID) async throws -> [ProjectProgressPhoto] {
        let remotePhotos: [ProjectProgressPhoto] = try await apiClient.get(
            "projects/\(projectId.uuidString.lowercased())/progress-photos"
        )

        var photosWithFiles: [ProjectProgressPhoto] = []
        for photo in remotePhotos {
            photosWithFiles.append(await photoWithDownloadedFile(photo))
        }

        return photosWithFiles
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
        let photo: ProjectProgressPhoto = try await apiClient.uploadMultipart(
            "projects/\(projectId.uuidString.lowercased())/progress-photos",
            fields: [
                "id": photoId.uuidString.lowercased(),
                "caption": caption.trimmingCharacters(in: .whitespacesAndNewlines),
                "takenAt": Self.iso8601String(from: takenAt),
            ],
            file: MultipartFile(
                fieldName: "file",
                fileName: fileName,
                contentType: contentType,
                data: imageData
            )
        )

        let storedFile = try fileStore.storePhotoData(
            imageData,
            fileName: photo.fileName,
            projectId: projectId,
            photoId: photo.id
        )
        return Self.copyPhoto(photo, localFilePath: storedFile.relativePath, syncStatus: .synced)
    }

    func updateProgressPhoto(
        _ photo: ProjectProgressPhoto,
        caption: String,
        takenAt: Date
    ) async throws -> ProjectProgressPhoto {
        let updatedPhoto: ProjectProgressPhoto = try await apiClient.send(
            "projects/\(photo.projectId.uuidString.lowercased())/progress-photos/\(photo.id.uuidString.lowercased())",
            method: "PATCH",
            body: SaveProjectProgressPhotoRequest(caption: caption, takenAt: takenAt)
        )

        return Self.copyPhoto(
            updatedPhoto,
            localFilePath: photo.localFilePath,
            syncStatus: .synced
        )
    }

    func deleteProgressPhoto(_ photo: ProjectProgressPhoto) async throws {
        try await apiClient.delete(
            "projects/\(photo.projectId.uuidString.lowercased())/progress-photos/\(photo.id.uuidString.lowercased())"
        )
        try fileStore.removeFile(at: photo.localFilePath)
    }

    func fileURL(for photo: ProjectProgressPhoto) -> URL? {
        fileStore.fileURL(for: photo.localFilePath)
    }

    private func photoWithDownloadedFile(_ photo: ProjectProgressPhoto) async -> ProjectProgressPhoto {
        do {
            let data = try await apiClient.downloadData(
                "projects/\(photo.projectId.uuidString.lowercased())/progress-photos/\(photo.id.uuidString.lowercased())/file"
            )
            let storedFile = try fileStore.storePhotoData(
                data,
                fileName: photo.fileName,
                projectId: photo.projectId,
                photoId: photo.id
            )
            return Self.copyPhoto(photo, localFilePath: storedFile.relativePath, syncStatus: .synced)
        } catch {
            return Self.copyPhoto(photo, localFilePath: nil, syncStatus: .synced)
        }
    }

    private static func copyPhoto(
        _ photo: ProjectProgressPhoto,
        localFilePath: String?,
        syncStatus: SyncStatus
    ) -> ProjectProgressPhoto {
        ProjectProgressPhoto(
            id: photo.id,
            ownerId: photo.ownerId,
            projectId: photo.projectId,
            fileName: photo.fileName,
            contentType: photo.contentType,
            byteSize: photo.byteSize,
            localFilePath: localFilePath,
            caption: photo.caption,
            takenAt: photo.takenAt,
            createdAt: photo.createdAt,
            updatedAt: photo.updatedAt,
            deletedAt: photo.deletedAt,
            syncStatus: syncStatus
        )
    }

    fileprivate static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private struct SaveProjectProgressPhotoRequest: Encodable {
    let caption: String
    let takenAt: String

    init(caption: String, takenAt: Date) {
        self.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        self.takenAt = RemoteProjectProgressPhotoRepository.iso8601String(from: takenAt)
    }
}
