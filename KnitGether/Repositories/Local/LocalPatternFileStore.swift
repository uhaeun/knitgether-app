//
//  LocalPatternFileStore.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

struct StoredPatternFile {
    let fileName: String
    let relativePath: String
}

final class LocalPatternFileStore {
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

    func storeLibraryPatternFile(from sourceURL: URL, patternId: UUID) throws -> StoredPatternFile {
        try copyFile(
            from: sourceURL,
            relativeDirectoryPath: "Patterns/\(patternId.uuidString)"
        )
    }

    func storeProjectPatternFile(
        from sourceURL: URL,
        projectId: UUID,
        copyId: UUID
    ) throws -> StoredPatternFile {
        try copyFile(
            from: sourceURL,
            relativeDirectoryPath: "Projects/\(projectId.uuidString)/Patterns/\(copyId.uuidString)"
        )
    }

    func storeProjectPatternData(
        _ data: Data,
        fileName: String,
        projectId: UUID,
        copyId: UUID
    ) throws -> StoredPatternFile {
        try writeFile(
            data,
            fileName: fileName,
            relativeDirectoryPath: "Projects/\(projectId.uuidString)/Patterns/\(copyId.uuidString)"
        )
    }

    func storeLibraryPatternData(
        _ data: Data,
        fileName: String,
        patternId: UUID
    ) throws -> StoredPatternFile {
        try writeFile(
            data,
            fileName: fileName,
            relativeDirectoryPath: "Patterns/\(patternId.uuidString)"
        )
    }

    func copyLibraryPatternFileToProject(
        _ pattern: PatternDocument,
        projectId: UUID,
        copyId: UUID
    ) throws -> StoredPatternFile? {
        guard let sourceURL = fileURL(for: pattern.localFilePath) else {
            return nil
        }

        return try storeProjectPatternFile(
            from: sourceURL,
            projectId: projectId,
            copyId: copyId
        )
    }

    func storeProjectPatternDrawingData(
        _ data: Data,
        projectId: UUID,
        copyId: UUID
    ) throws -> String {
        let relativePath = "Projects/\(projectId.uuidString)/Patterns/\(copyId.uuidString)/drawing.pkdrawing"
        let destinationURL = rootDirectoryURL.appendingPathComponent(relativePath)
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()

        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        try data.write(to: destinationURL, options: [.atomic])

        return relativePath
    }

    func loadData(at relativePath: String?) throws -> Data? {
        guard
            let fileURL = fileURL(for: relativePath),
            fileManager.fileExists(atPath: fileURL.path)
        else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    func fileURL(for relativePath: String?) -> URL? {
        guard let relativePath, !relativePath.isEmpty else {
            return nil
        }

        return rootDirectoryURL.appendingPathComponent(relativePath)
    }

    func removeFile(at relativePath: String?) throws {
        guard
            let fileURL = fileURL(for: relativePath),
            fileManager.fileExists(atPath: fileURL.path)
        else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func copyFile(
        from sourceURL: URL,
        relativeDirectoryPath: String
    ) throws -> StoredPatternFile {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = sanitizedFileName(sourceURL.lastPathComponent)
        let relativePath = "\(relativeDirectoryPath)/\(fileName)"
        let destinationURL = rootDirectoryURL.appendingPathComponent(relativePath)
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()

        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return StoredPatternFile(fileName: fileName, relativePath: relativePath)
    }

    private func writeFile(
        _ data: Data,
        fileName: String,
        relativeDirectoryPath: String
    ) throws -> StoredPatternFile {
        let sanitizedName = sanitizedFileName(fileName)
        let relativePath = "\(relativeDirectoryPath)/\(sanitizedName)"
        let destinationURL = rootDirectoryURL.appendingPathComponent(relativePath)
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()

        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL, options: [.atomic])

        return StoredPatternFile(fileName: sanitizedName, relativePath: relativePath)
    }

    private func sanitizedFileName(_ fileName: String) -> String {
        let fallback = "pattern.pdf"
        let candidate = fileName.isEmpty ? fallback : fileName
        let invalidCharacters = CharacterSet(charactersIn: "/:")

        return candidate
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
    }
}
