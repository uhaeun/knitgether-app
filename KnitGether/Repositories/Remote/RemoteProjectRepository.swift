import Foundation

final class RemoteProjectRepository: ProjectRepository {
    private let apiClient: APIClient
    private let fileStore: LocalPatternFileStore

    /// 프로젝트별로 마지막으로 확인한 서버 updatedAt.
    /// 저장(PATCH) 시 baseUpdatedAt으로 함께 보내 낙관적 잠금(409 PROJECT_CONFLICT)의 기준이 된다.
    ///
    /// 앱 재시작을 넘겨 보존한다(GitHub #14). 메모리에만 두면 재시작 직후 첫 저장이
    /// baseUpdatedAt 없이 나가고 서버는 그 요청을 last-write-wins로 통과시킨다. 다른 기기가
    /// 고친 것을 만나는 상황은 대개 앱을 다시 켰을 때이므로, 보호가 가장 필요한 순간에 꺼져
    /// 있게 된다. 보존한 값이 낡았더라도 서버 updatedAt이 그보다 뒤일 때만 409가 나므로,
    /// 그동안 서버가 바뀌지 않았다면 저장은 그대로 통과한다.
    private let serverUpdatedAtLock = NSLock()
    private var lastKnownServerUpdatedAtByProjectId: [UUID: Date] = [:]
    private let serverUpdatedAtStore: UserDefaults
    private static let serverUpdatedAtKey = "KnitGether.remote.lastKnownServerUpdatedAt"

    init(
        apiClient: APIClient,
        fileStore: LocalPatternFileStore = LocalPatternFileStore(),
        serverUpdatedAtStore: UserDefaults = .standard
    ) {
        self.apiClient = apiClient
        self.fileStore = fileStore
        self.serverUpdatedAtStore = serverUpdatedAtStore
        self.lastKnownServerUpdatedAtByProjectId = Self.loadServerUpdatedAt(from: serverUpdatedAtStore)
    }

    private static func loadServerUpdatedAt(from store: UserDefaults) -> [UUID: Date] {
        guard let raw = store.dictionary(forKey: serverUpdatedAtKey) as? [String: Double] else {
            return [:]
        }

        return raw.reduce(into: [:]) { result, entry in
            guard let id = UUID(uuidString: entry.key) else {
                return
            }
            result[id] = Date(timeIntervalSince1970: entry.value)
        }
    }

    /// 잠금을 쥔 상태에서만 호출한다.
    private func persistServerUpdatedAtLocked() {
        let raw = lastKnownServerUpdatedAtByProjectId.reduce(into: [String: Double]()) { result, entry in
            result[entry.key.uuidString] = entry.value.timeIntervalSince1970
        }
        serverUpdatedAtStore.set(raw, forKey: Self.serverUpdatedAtKey)
    }

    func fetchProjects() async throws -> [KnittingProject] {
        let projects: [KnittingProject] = try await apiClient.get("projects")
        projects.forEach(recordServerUpdatedAt)
        return try await projects.asyncMap { project in
            try await cachePatternCopyFileIfNeeded(for: project)
        }
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        do {
            let project: KnittingProject = try await apiClient.get("projects/\(id.uuidString.lowercased())")
            recordServerUpdatedAt(project)
            return try await cachePatternCopyFileIfNeeded(for: project)
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveProject(_ project: KnittingProject) async throws {
        if await shouldUpdateExistingProject(project) {
            let body = SaveProjectRequest(
                project: project,
                baseUpdatedAt: await resolvedBaseUpdatedAt(forProjectId: project.id)
            )
            let savedProject: KnittingProject = try await apiClient.send(
                "projects/\(project.id.uuidString.lowercased())",
                method: "PATCH",
                body: body
            )
            recordServerUpdatedAt(savedProject)
        } else {
            let savedProject: KnittingProject = try await apiClient.send(
                "projects",
                method: "POST",
                body: SaveProjectRequest(project: project, baseUpdatedAt: nil)
            )
            recordServerUpdatedAt(savedProject)
        }

        try await uploadDirectPatternCopyFileIfNeeded(for: project)
        try await uploadPatternCopyDrawingIfNeeded(for: project)
    }

    private func recordServerUpdatedAt(_ project: KnittingProject) {
        serverUpdatedAtLock.lock()
        defer {
            serverUpdatedAtLock.unlock()
        }
        lastKnownServerUpdatedAtByProjectId[project.id] = project.updatedAt
        persistServerUpdatedAtLocked()
    }

    /// 수정(PATCH)으로 보낼지 생성(POST)으로 보낼지 정한다.
    ///
    /// 예전에는 syncStatus가 synced인 경우만 PATCH였다. 그래서 충돌로 표시된 프로젝트를
    /// 사용자가 다시 수정하면 POST로 나갔고, POST는 서버에서 업서트로 동작하면서
    /// baseUpdatedAt을 싣지 않아 낙관적 잠금을 통째로 건너뛰었다. 충돌을 보고 고치려 드는
    /// 것은 자연스러운 행동인데 고치는 순간 보호가 꺼지는 셈이었다(GitHub #14 잔존).
    ///
    /// conflict는 두 곳에서 생기고 서로 다르다. SYNC-09는 서버에 존재한 적 없는 localOnly가
    /// 거부된 것이고, SYNC-10은 서버에 있는 것을 고치다 거부된 것이다. 상태값만으로는
    /// 둘을 가를 수 없다.
    ///
    /// 그래서 상태 대신 기준값의 유무로 가른다. 서버 updatedAt을 알고 있다는 것은 그
    /// 프로젝트를 서버에서 본 적이 있다는 뜻이다. 모르면 서버에 한 번 물어보고, 그래도
    /// 없으면 서버에 없는 것으로 보고 POST로 만든다.
    private func shouldUpdateExistingProject(_ project: KnittingProject) async -> Bool {
        if project.syncStatus == .synced {
            return true
        }

        guard project.syncStatus == .conflict else {
            return false
        }

        return await resolvedBaseUpdatedAt(forProjectId: project.id) != nil
    }

    /// 저장에 쓸 낙관적 잠금 기준값. 기억하고 있는 값이 없으면 서버에서 한 번 읽어 온다.
    ///
    /// 서버는 기준값 없는 수정을 400으로 거부한다(GitHub #14). 거부 자체는 옳다. 예전처럼
    /// 그냥 통과시키면 다른 기기의 수정을 무통보로 덮어쓰기 때문이다. 다만 기준값을 잃은
    /// 것이 사용자 잘못은 아니므로, 사용자에게 오류를 보이기 전에 스스로 되찾아 본다.
    ///
    /// 읽기에 실패하면 nil 그대로 보낸다. 그 경우 서버가 거부하고, 그것이 조용히 덮어쓰는
    /// 것보다 낫다.
    private func resolvedBaseUpdatedAt(forProjectId id: UUID) async -> Date? {
        if let known = lastKnownServerUpdatedAt(forProjectId: id) {
            return known
        }

        _ = try? await fetchProject(id: id)
        return lastKnownServerUpdatedAt(forProjectId: id)
    }

    private func lastKnownServerUpdatedAt(forProjectId id: UUID) -> Date? {
        serverUpdatedAtLock.lock()
        defer {
            serverUpdatedAtLock.unlock()
        }
        return lastKnownServerUpdatedAtByProjectId[id]
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
    // JSONEncoder는 nil 옵셔널을 필드 생략으로 인코딩해, 도안 해제(patternCopy 없음)가
    // 서버에 undefined(no-op)로 도착해 복사본이 잔존했다(결함 18). 해제 신호가 전달되도록
    // 명시적 null을 인코딩한다. 서버는 null이면 복사본을 제거한다.
    let patternCopy: ExplicitNullEncodable<SaveProjectPatternCopyRequest>
    let rowCounter: SaveRowCounterRequest
    let workSessions: [SaveWorkSessionRequest]
    /// 클라이언트가 마지막으로 확인한 서버 updatedAt. 서버는 이 값이 자신의 updatedAt보다
    /// 오래되면 409(code: PROJECT_CONFLICT)로 거부한다. nil이면 필드를 생략한다.
    let baseUpdatedAt: Date?

    nonisolated init(project: KnittingProject, baseUpdatedAt: Date? = nil) {
        self.baseUpdatedAt = baseUpdatedAt
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
        patternCopy = ExplicitNullEncodable(project.patternCopy.map(SaveProjectPatternCopyRequest.init))
        rowCounter = SaveRowCounterRequest(rowCounter: project.rowCounter)
        workSessions = project.workSessions.map(SaveWorkSessionRequest.init)
    }
}

/// nil을 필드 생략이 아니라 JSON null로 인코딩한다.
private struct ExplicitNullEncodable<Wrapped: Encodable>: Encodable {
    let wrapped: Wrapped?

    init(_ wrapped: Wrapped?) {
        self.wrapped = wrapped
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let wrapped {
            try container.encode(wrapped)
        } else {
            try container.encodeNil()
        }
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
