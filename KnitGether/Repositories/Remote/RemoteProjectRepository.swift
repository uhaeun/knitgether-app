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

        try await uploadDirectPatternCopyFileIfNeeded(for: project)
        try await uploadPatternCopyDrawingIfNeeded(for: project)
    }

    func deleteProject(id: UUID) async throws {
        try await apiClient.delete("projects/\(id.uuidString.lowercased())")
    }

    func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter {
        try await apiClient.send(
            "projects/\(projectId.uuidString.lowercased())/row-counter",
            method: "PATCH",
            body: SaveRowCounterRequest(rowCounter: rowCounter)
        )
    }

    func saveRowInstruction(_ instruction: RowInstruction, forProjectId projectId: UUID) async throws -> RowInstruction {
        let method = instruction.syncStatus == .localOnly ? "POST" : "PATCH"
        let path = instruction.syncStatus == .localOnly
            ? "projects/\(projectId.uuidString.lowercased())/row-instructions"
            : "projects/\(projectId.uuidString.lowercased())/row-instructions/\(instruction.id.uuidString.lowercased())"

        return try await apiClient.send(
            path,
            method: method,
            body: SaveRowInstructionRequest(rowInstruction: instruction)
        )
    }

    func deleteRowInstruction(id: UUID, forProjectId projectId: UUID) async throws {
        try await apiClient.delete(
            "projects/\(projectId.uuidString.lowercased())/row-instructions/\(id.uuidString.lowercased())"
        )
    }

    func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
        let method = session.syncStatus == .localOnly ? "POST" : "PATCH"
        let path = session.syncStatus == .localOnly
            ? "projects/\(projectId.uuidString.lowercased())/work-sessions"
            : "projects/\(projectId.uuidString.lowercased())/work-sessions/\(session.id.uuidString.lowercased())"

        return try await apiClient.send(
            path,
            method: method,
            body: SaveWorkSessionRequest(workSession: session)
        )
    }

    func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
        try await apiClient.delete(
            "projects/\(projectId.uuidString.lowercased())/work-sessions/\(id.uuidString.lowercased())"
        )
    }

    private func cachePatternCopyFileIfNeeded(for project: KnittingProject) async throws -> KnittingProject {
        guard let patternCopy = project.patternCopy else {
            return project
        }

        var cachedPatternCopy = patternCopy

        if let localCopyPath = patternCopy.localCopyPath,
           fileExists(at: localCopyPath) {
            cachedPatternCopy = patternCopy
        } else {
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
                cachedPatternCopy = ProjectPatternCopy(
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
            } catch let error as APIError where error.statusCode == 404 {
                cachedPatternCopy = patternCopy
            }
        }

        cachedPatternCopy = try await cachePatternCopyDrawingIfNeeded(
            cachedPatternCopy,
            for: project
        )

        return project.copy(
            patternCopy: cachedPatternCopy,
            updatedAt: project.updatedAt
        )
    }

    private func cachePatternCopyDrawingIfNeeded(
        _ patternCopy: ProjectPatternCopy,
        for project: KnittingProject
    ) async throws -> ProjectPatternCopy {
        guard patternCopy.drawingUpdatedAt != nil else {
            return patternCopy
        }

        if let drawingDataPath = patternCopy.drawingDataPath,
           fileExists(at: drawingDataPath) {
            return patternCopy
        }

        do {
            let drawingData = try await apiClient.downloadData(
                "projects/\(project.id.uuidString.lowercased())/pattern-copy/drawing"
            )
            let relativePath = try fileStore.storeProjectPatternDrawingData(
                drawingData,
                projectId: patternCopy.projectId,
                copyId: patternCopy.id
            )

            return ProjectPatternCopy(
                id: patternCopy.id,
                ownerId: patternCopy.ownerId,
                projectId: patternCopy.projectId,
                sourcePatternDocumentId: patternCopy.sourcePatternDocumentId,
                titleSnapshot: patternCopy.titleSnapshot,
                designerSnapshot: patternCopy.designerSnapshot,
                fileNameSnapshot: patternCopy.fileNameSnapshot,
                localCopyPath: patternCopy.localCopyPath,
                pageCountSnapshot: patternCopy.pageCountSnapshot,
                drawingDataPath: relativePath,
                drawingUpdatedAt: patternCopy.drawingUpdatedAt,
                copiedAt: patternCopy.copiedAt,
                createdAt: patternCopy.createdAt,
                updatedAt: patternCopy.updatedAt,
                deletedAt: patternCopy.deletedAt,
                syncStatus: patternCopy.syncStatus
            )
        } catch let error as APIError where error.statusCode == 404 {
            return patternCopy
        }
    }

    private func uploadDirectPatternCopyFileIfNeeded(for project: KnittingProject) async throws {
        guard
            let patternCopy = project.patternCopy,
            patternCopy.sourcePatternDocumentId == nil,
            let localCopyURL = fileStore.fileURL(for: patternCopy.localCopyPath),
            FileManager.default.fileExists(atPath: localCopyURL.path)
        else {
            return
        }

        let fileData = try Data(contentsOf: localCopyURL)
        let _: ProjectPatternCopy = try await apiClient.uploadMultipart(
            "projects/\(project.id.uuidString.lowercased())/pattern-copy/file",
            fields: [:],
            file: MultipartFile(
                fieldName: "file",
                fileName: patternCopy.fileNameSnapshot ?? localCopyURL.lastPathComponent,
                contentType: "application/pdf",
                data: fileData
            )
        )
    }

    private func uploadPatternCopyDrawingIfNeeded(for project: KnittingProject) async throws {
        guard
            let patternCopy = project.patternCopy,
            let drawingDataPath = patternCopy.drawingDataPath,
            let drawingURL = fileStore.fileURL(for: drawingDataPath),
            FileManager.default.fileExists(atPath: drawingURL.path)
        else {
            return
        }

        let drawingData = try Data(contentsOf: drawingURL)
        let _: ProjectPatternCopy = try await apiClient.uploadMultipart(
            "projects/\(project.id.uuidString.lowercased())/pattern-copy/drawing",
            fields: [:],
            file: MultipartFile(
                fieldName: "file",
                fileName: "drawing.pkdrawing",
                contentType: "application/octet-stream",
                data: drawingData
            )
        )
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
    let targetDate: Date?
    let finishedAt: Date?
    let lastWorkedAt: Date?
    let yarnId: String?
    let yarnNameSnapshot: String?
    let yarnBrandSnapshot: String?
    let yarnColorwaySnapshot: String?
    let yarnWeightSnapshot: String?
    let needleId: String?
    let needleNameSnapshot: String?
    let needleTypeSnapshot: String?
    let needleSizeSnapshot: String?
    let needleLengthSnapshot: String?
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
        targetDate = project.targetDate
        finishedAt = project.finishedAt
        lastWorkedAt = project.lastWorkedAt
        yarnId = project.yarnId?.uuidString.lowercased()
        yarnNameSnapshot = project.yarnNameSnapshot
        yarnBrandSnapshot = project.yarnBrandSnapshot
        yarnColorwaySnapshot = project.yarnColorwaySnapshot
        yarnWeightSnapshot = project.yarnWeightSnapshot
        needleId = project.needleId?.uuidString.lowercased()
        needleNameSnapshot = project.needleNameSnapshot
        needleTypeSnapshot = project.needleTypeSnapshot
        needleSizeSnapshot = project.needleSizeSnapshot
        needleLengthSnapshot = project.needleLengthSnapshot
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
    let mode: String
    let sectionName: String?
    let memo: String?
    let currentRow: Int
    let targetRow: Int?
    let rowInstructions: [SaveRowInstructionRequest]

    nonisolated init(rowCounter: RowCounter) {
        id = rowCounter.id.uuidString.lowercased()
        projectId = rowCounter.projectId.uuidString.lowercased()
        name = rowCounter.name
        mode = rowCounter.mode.rawValue
        sectionName = rowCounter.sectionName
        memo = rowCounter.memo
        currentRow = rowCounter.currentRow
        targetRow = rowCounter.targetRow
        rowInstructions = rowCounter.rowInstructions.map(SaveRowInstructionRequest.init)
    }
}

private struct SaveRowInstructionRequest: Encodable {
    let id: String
    let rowCounterId: String
    let rowNumber: Int
    let instructionText: String
    let skillTags: String?

    nonisolated init(rowInstruction: RowInstruction) {
        id = rowInstruction.id.uuidString.lowercased()
        rowCounterId = rowInstruction.rowCounterId.uuidString.lowercased()
        rowNumber = rowInstruction.rowNumber
        instructionText = rowInstruction.instructionText
        skillTags = rowInstruction.skillTags
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
