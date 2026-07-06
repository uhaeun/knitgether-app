import Foundation

final class RemotePatternRepository: PatternRepository {
    private let apiClient: APIClient
    private let fileStore: LocalPatternFileStore
    private var cachedPatterns: [UUID: PatternDocument] = [:]

    init(
        apiClient: APIClient,
        fileStore: LocalPatternFileStore = LocalPatternFileStore()
    ) {
        self.apiClient = apiClient
        self.fileStore = fileStore
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        let patterns: [PatternDocument] = try await apiClient.get("patterns")
        return patterns.map { mergeCachedPath(into: $0) }
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        do {
            let pattern: PatternDocument = try await apiClient.get("patterns/\(id.uuidString.lowercased())")
            return try await cacheFileIfNeeded(for: mergeCachedPath(into: pattern))
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        let body = SavePatternRequest(pattern: pattern)
        let updated: PatternDocument = try await apiClient.send(
            "patterns/\(pattern.id.uuidString.lowercased())",
            method: "PATCH",
            body: body
        )
        cachedPatterns[updated.id] = mergeCachedPath(into: updated)
    }

    func deletePattern(id: UUID) async throws {
        try await apiClient.delete("patterns/\(id.uuidString.lowercased())")

        if let cached = cachedPatterns[id] {
            try fileStore.removeFile(at: cached.localFilePath)
        }
        cachedPatterns[id] = nil
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileData = try Data(contentsOf: fileURL)
        let title = fileURL.deletingPathExtension().lastPathComponent
        let uploaded: PatternDocument = try await apiClient.uploadMultipart(
            "patterns",
            fields: ["title": title],
            file: MultipartFile(
                fieldName: "file",
                fileName: fileURL.lastPathComponent,
                contentType: "application/pdf",
                data: fileData
            )
        )

        return try await cacheFileIfNeeded(for: uploaded)
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let cachedPattern = try await cacheFileIfNeeded(for: mergeCachedPath(into: pattern))
        let copyId = UUID()
        let copiedFile = try fileStore.copyLibraryPatternFileToProject(
            cachedPattern,
            projectId: projectId,
            copyId: copyId
        )
        let now = Date()

        return ProjectPatternCopy(
            id: copyId,
            ownerId: cachedPattern.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: cachedPattern.id,
            titleSnapshot: cachedPattern.title,
            designerSnapshot: cachedPattern.designer,
            fileNameSnapshot: copiedFile?.fileName ?? cachedPattern.fileName,
            localCopyPath: copiedFile?.relativePath,
            pageCountSnapshot: cachedPattern.pageCount,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileData = try Data(contentsOf: fileURL)
        let title = fileURL.deletingPathExtension().lastPathComponent
        let uploaded: PatternDocument = try await apiClient.uploadMultipart(
            "patterns",
            fields: ["title": title],
            file: MultipartFile(
                fieldName: "file",
                fileName: fileURL.lastPathComponent,
                contentType: "application/pdf",
                data: fileData
            )
        )
        let cachedPattern = try await cacheFileIfNeeded(for: uploaded)
        let copyId = UUID()
        let copiedFile = try fileStore.copyLibraryPatternFileToProject(
            cachedPattern,
            projectId: projectId,
            copyId: copyId
        )
        let now = Date()

        return ProjectPatternCopy(
            id: copyId,
            ownerId: cachedPattern.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: cachedPattern.id,
            titleSnapshot: cachedPattern.title,
            designerSnapshot: cachedPattern.designer,
            fileNameSnapshot: copiedFile?.fileName ?? cachedPattern.fileName,
            localCopyPath: copiedFile?.relativePath,
            pageCountSnapshot: cachedPattern.pageCount,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        fileStore.fileURL(for: pattern.localFilePath ?? cachedPatterns[pattern.id]?.localFilePath)
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        fileStore.fileURL(for: patternCopy.localCopyPath)
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        try fileStore.loadData(at: patternCopy.drawingDataPath)
    }

    func saveDrawingData(
        _ data: Data,
        for patternCopy: ProjectPatternCopy
    ) async throws -> ProjectPatternCopy {
        let relativePath = try fileStore.storeProjectPatternDrawingData(
            data,
            projectId: patternCopy.projectId,
            copyId: patternCopy.id
        )
        let uploaded: ProjectPatternCopy = try await apiClient.uploadMultipart(
            "projects/\(patternCopy.projectId.uuidString.lowercased())/pattern-copy/drawing",
            fields: [:],
            file: MultipartFile(
                fieldName: "file",
                fileName: "drawing.pkdrawing",
                contentType: "application/octet-stream",
                data: data
            )
        )

        return ProjectPatternCopy(
            id: uploaded.id,
            ownerId: uploaded.ownerId,
            projectId: uploaded.projectId,
            sourcePatternDocumentId: uploaded.sourcePatternDocumentId,
            titleSnapshot: uploaded.titleSnapshot,
            designerSnapshot: uploaded.designerSnapshot,
            fileNameSnapshot: uploaded.fileNameSnapshot,
            localCopyPath: patternCopy.localCopyPath,
            pageCountSnapshot: uploaded.pageCountSnapshot,
            drawingDataPath: relativePath,
            drawingUpdatedAt: uploaded.drawingUpdatedAt,
            copiedAt: uploaded.copiedAt,
            createdAt: uploaded.createdAt,
            updatedAt: uploaded.updatedAt,
            deletedAt: uploaded.deletedAt,
            syncStatus: uploaded.syncStatus
        )
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        do {
            try await apiClient.delete(
                "projects/\(patternCopy.projectId.uuidString.lowercased())/pattern-copy/drawing"
            )
        } catch let error as APIError where error.statusCode == 404 {
            // Local drawing can still be cleared if the server no longer has a copy.
        }

        try fileStore.removeFile(at: patternCopy.drawingDataPath)
        return patternCopy.updatingDrawingDataPath(nil)
    }

    private func cacheFileIfNeeded(for pattern: PatternDocument) async throws -> PatternDocument {
        if let localFilePath = pattern.localFilePath,
           fileExists(at: localFilePath) {
            cachedPatterns[pattern.id] = pattern
            return pattern
        }

        if let cached = cachedPatterns[pattern.id],
           let cachedPath = cached.localFilePath,
           fileExists(at: cachedPath) {
            return cached
        }

        let fileData = try await apiClient.downloadData("patterns/\(pattern.id.uuidString.lowercased())/file")
        let stored = try fileStore.storeLibraryPatternData(
            fileData,
            fileName: pattern.fileName ?? "\(pattern.title).pdf",
            patternId: pattern.id
        )
        let cached = PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId,
            title: pattern.title,
            designer: pattern.designer,
            fileName: stored.fileName,
            localFilePath: stored.relativePath,
            pageCount: pattern.pageCount,
            notes: pattern.notes,
            createdAt: pattern.createdAt,
            updatedAt: pattern.updatedAt,
            deletedAt: pattern.deletedAt,
            syncStatus: pattern.syncStatus
        )
        cachedPatterns[pattern.id] = cached
        return cached
    }

    private func mergeCachedPath(into pattern: PatternDocument) -> PatternDocument {
        guard let cached = cachedPatterns[pattern.id],
              let cachedPath = cached.localFilePath
        else {
            return pattern
        }

        return PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId,
            title: pattern.title,
            designer: pattern.designer,
            fileName: pattern.fileName,
            localFilePath: cachedPath,
            pageCount: pattern.pageCount,
            notes: pattern.notes,
            createdAt: pattern.createdAt,
            updatedAt: pattern.updatedAt,
            deletedAt: pattern.deletedAt,
            syncStatus: pattern.syncStatus
        )
    }

    private func fileExists(at relativePath: String) -> Bool {
        guard let url = fileStore.fileURL(for: relativePath) else {
            return false
        }

        return FileManager.default.fileExists(atPath: url.path)
    }
}

private struct SavePatternRequest: Encodable {
    let title: String
    let designer: String?
    let pageCount: Int?
    let notes: String

    nonisolated init(pattern: PatternDocument) {
        title = pattern.title
        designer = pattern.designer
        pageCount = pattern.pageCount
        notes = pattern.notes
    }
}
