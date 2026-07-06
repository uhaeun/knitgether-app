import Foundation

final class RemoteProjectRepository: ProjectRepository {
    private let apiClient: APIClient
    private let fileStore: LocalPatternFileStore

    init(
        apiClient: APIClient,
        fileStore: LocalPatternFileStore = LocalPatternFileStore()
    ) {
        self.apiClient = apiClient
        self.fileStore = fileStore
    }

    func fetchProjects() async throws -> [KnittingProject] {
        let projects: [KnittingProject] = try await apiClient.get("projects")
        return try await projects.asyncMap { project in
            try await cachePatternCopyFileIfNeeded(for: project)
        }
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        do {
            let project: KnittingProject = try await apiClient.get("projects/\(id.uuidString.lowercased())")
            return try await cachePatternCopyFileIfNeeded(for: project)
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveProject(_ project: KnittingProject) async throws {
        let body = SaveProjectRequest(project: project)

        if project.syncStatus == .synced {
            let _: KnittingProject = try await apiClient.send(
                "projects/\(project.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
        } else {
            let _: KnittingProject = try await apiClient.send(
                "projects",
                method: "POST",
                body: body
            )
        }
    }

    func deleteProject(id: UUID) async throws {
        try await apiClient.delete("projects/\(id.uuidString.lowercased())")
    }

    private func cachePatternCopyFileIfNeeded(for project: KnittingProject) async throws -> KnittingProject {
        guard let patternCopy = project.patternCopy else {
            return project
        }

        if let localCopyPath = patternCopy.localCopyPath,
           fileExists(at: localCopyPath) {
            return project
        }

        do {
            let fileData = try await apiClient.downloadData(
                "projects/\(project.id.uuidString.lowercased())/pattern-copy/file"
            )
            let storedFile = try fileStore.storeProjectPatternData(
                fileData,
                fileName: patternCopy.fileNameSnapshot ?? "\(patternCopy.titleSnapshot).pdf",
                projectId: project.id,
                copyId: patternCopy.id
            )
            let cachedPatternCopy = ProjectPatternCopy(
                id: patternCopy.id,
                ownerId: patternCopy.ownerId,
                projectId: patternCopy.projectId,
                sourcePatternDocumentId: patternCopy.sourcePatternDocumentId,
                titleSnapshot: patternCopy.titleSnapshot,
                designerSnapshot: patternCopy.designerSnapshot,
                fileNameSnapshot: storedFile.fileName,
                localCopyPath: storedFile.relativePath,
                pageCountSnapshot: patternCopy.pageCountSnapshot,
                drawingDataPath: patternCopy.drawingDataPath,
                drawingUpdatedAt: patternCopy.drawingUpdatedAt,
                copiedAt: patternCopy.copiedAt,
                createdAt: patternCopy.createdAt,
                updatedAt: patternCopy.updatedAt,
                deletedAt: patternCopy.deletedAt,
                syncStatus: patternCopy.syncStatus
            )

            return project.copy(
                patternCopy: cachedPatternCopy,
                updatedAt: project.updatedAt
            )
        } catch let error as APIError where error.statusCode == 404 {
            return project
        }
    }

    private func fileExists(at relativePath: String) -> Bool {
        guard let url = fileStore.fileURL(for: relativePath) else {
            return false
        }

        return FileManager.default.fileExists(atPath: url.path)
    }
}

private struct SaveProjectRequest: Encodable {
    let id: String
    let name: String
    let status: String
    let isFavorite: Bool
    let memo: String
    let startDate: Date
    let lastWorkedAt: Date?
    let workspaceDisplayMode: String?
    let workspaceSheetPosition: String?
    let relatedSkillIds: [String]
    let patternCopy: SaveProjectPatternCopyRequest?
    let rowCounter: SaveRowCounterRequest
    let workSessions: [SaveWorkSessionRequest]

    nonisolated init(project: KnittingProject) {
        id = project.id.uuidString.lowercased()
        name = project.name
        status = project.status.rawValue
        isFavorite = project.isFavorite
        memo = project.memo
        startDate = project.startDate
        lastWorkedAt = project.lastWorkedAt
        workspaceDisplayMode = project.workspaceDisplayMode?.rawValue
        workspaceSheetPosition = project.workspaceSheetPosition?.rawValue
        relatedSkillIds = project.relatedSkillIds.map { $0.uuidString.lowercased() }
        patternCopy = project.patternCopy.map(SaveProjectPatternCopyRequest.init)
        rowCounter = SaveRowCounterRequest(rowCounter: project.rowCounter)
        workSessions = project.workSessions.map(SaveWorkSessionRequest.init)
    }
}

private struct SaveProjectPatternCopyRequest: Encodable {
    let id: String
    let projectId: String
    let sourcePatternDocumentId: String?
    let titleSnapshot: String
    let designerSnapshot: String?
    let fileNameSnapshot: String?
    let localCopyPath: String?
    let pageCountSnapshot: Int?
    let drawingDataPath: String?
    let drawingUpdatedAt: Date?
    let copiedAt: Date

    nonisolated init(patternCopy: ProjectPatternCopy) {
        id = patternCopy.id.uuidString.lowercased()
        projectId = patternCopy.projectId.uuidString.lowercased()
        sourcePatternDocumentId = patternCopy.sourcePatternDocumentId?.uuidString.lowercased()
        titleSnapshot = patternCopy.titleSnapshot
        designerSnapshot = patternCopy.designerSnapshot
        fileNameSnapshot = patternCopy.fileNameSnapshot
        localCopyPath = patternCopy.localCopyPath
        pageCountSnapshot = patternCopy.pageCountSnapshot
        drawingDataPath = patternCopy.drawingDataPath
        drawingUpdatedAt = patternCopy.drawingUpdatedAt
        copiedAt = patternCopy.copiedAt
    }
}

private struct SaveRowCounterRequest: Encodable {
    let id: String
    let projectId: String
    let name: String
    let currentRow: Int
    let targetRow: Int?

    nonisolated init(rowCounter: RowCounter) {
        id = rowCounter.id.uuidString.lowercased()
        projectId = rowCounter.projectId.uuidString.lowercased()
        name = rowCounter.name
        currentRow = rowCounter.currentRow
        targetRow = rowCounter.targetRow
    }
}

private struct SaveWorkSessionRequest: Encodable {
    let id: String
    let projectId: String
    let startedAt: Date
    let endedAt: Date?
    let memo: String?

    nonisolated init(workSession: WorkSession) {
        id = workSession.id.uuidString.lowercased()
        projectId = workSession.projectId.uuidString.lowercased()
        startedAt = workSession.startedAt
        endedAt = workSession.endedAt
        memo = workSession.memo
    }
}

private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values: [T] = []
        values.reserveCapacity(count)

        for element in self {
            let value = try await transform(element)
            values.append(value)
        }

        return values
    }
}
