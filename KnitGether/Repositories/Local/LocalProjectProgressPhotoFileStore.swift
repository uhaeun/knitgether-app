//
//  LocalProjectProgressPhotoFileStore.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Foundation

struct StoredProgressPhotoFile {
    let fileName: String
    let relativePath: String
}

final class LocalProjectProgressPhotoFileStore {
    private let fileManager: FileManager
    private let rootDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        rootDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager

        if let rootDirectoryURL {
            self.rootDirectoryURL = rootDirectoryURL
        } else {
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.rootDirectoryURL = documentsURL.appendingPathComponent("KnitGetherFiles", isDirectory: true)
        }
    }

    func storePhotoData(
        _ data: Data,
        fileName: String,
        projectId: UUID,
        photoId: UUID
    ) throws -> StoredProgressPhotoFile {
        let sanitizedName = sanitizedFileName(fileName)
        let relativePath = "Projects/\(projectId.uuidString)/ProgressPhotos/\(photoId.uuidString)/\(sanitizedName)"
        let destinationURL = rootDirectoryURL.appendingPathComponent(relativePath)
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()

        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL, options: [.atomic])
        return StoredProgressPhotoFile(fileName: sanitizedName, relativePath: relativePath)
    }

    func fileURL(for relativePath: String?) -> URL? {
        guard let relativePath, !relativePath.isEmpty else {
            return nil
        }

        return rootDirectoryURL.appendingPathComponent(relativePath)
    }

    func data(for relativePath: String?) throws -> Data? {
        guard let fileURL = fileURL(for: relativePath), fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    func removeFile(at relativePath: String?) throws {
        guard let fileURL = fileURL(for: relativePath), fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func sanitizedFileName(_ fileName: String) -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "progress-photo.jpg" : trimmed
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

        return fallback.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? String(scalar) : "_"
        }
        .joined()
    }
}
