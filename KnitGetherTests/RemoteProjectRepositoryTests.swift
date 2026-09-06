import Foundation
import Testing
@testable import KnitGether

struct RemoteProjectRepositoryTests {
    @Test func fetchProjectsRequestsProjectsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectsResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        let projects = try await repository.fetchProjects()

        #expect(projects.count == 1)
        guard let project = projects.first else {
            Issue.record("Expected one project")
            return
        }

        #expect(project.id.uuidString.lowercased() == "11111111-1111-4111-8111-111111111111")
        #expect(project.ownerId == "user-a")
        #expect(project.name == "Favorite Cardigan")
        #expect(project.status == .wip)
        #expect(project.isFavorite)
        #expect(project.memo == "Use smaller needles for ribbing.")
        #expect(project.targetDate == Self.date("2026-08-15T00:00:00.000Z"))
        #expect(project.finishedAt == nil)
        #expect(project.patternCopy == nil)
        #expect(project.yarnId?.uuidString.lowercased() == "cccccccc-cccc-4ccc-8ccc-cccccccccccc")
        #expect(project.yarnNameSnapshot == "Soft Merino DK")
        #expect(project.yarnBrandSnapshot == "Sample Yarn Co.")
        #expect(project.yarnColorwaySnapshot == "Cloud Gray")
        #expect(project.yarnWeightSnapshot == "DK")
        #expect(project.needleId?.uuidString.lowercased() == "dddddddd-dddd-4ddd-8ddd-dddddddddddd")
        #expect(project.needleNameSnapshot == "Wood Circular Needle")
        #expect(project.needleTypeSnapshot == "Circular")
        #expect(project.needleSizeSnapshot == "5.0 mm")
        #expect(project.needleLengthSnapshot == "80 cm")
        #expect(project.workspaceDisplayMode == .patternAndCounter)
        #expect(project.workspaceSheetPosition == .medium)
        #expect(project.rowCounter.currentRow == 42)
        #expect(project.rowCounter.targetRow == 120)
        #expect(project.workSessions.count == 1)
        #expect(project.workSessions.first?.memo == "Sleeve increases.")
        #expect(project.relatedSkillIds.map(\.uuidString).map { $0.lowercased() } == [
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        ])
        #expect(project.syncStatus == .synced)
    }

    @Test func fetchProjectsDownloadsPatternCopyFileWhenCacheIsMissing() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.projectsWithPatternCopyResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/file")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )

        let project = try #require(try await repository.fetchProjects().first)
        let patternCopy = try #require(project.patternCopy)
        let localCopyPath = try #require(patternCopy.localCopyPath)

        #expect(callCount == 2)
        #expect(localCopyPath.contains("Projects/11111111-1111-4111-8111-111111111111/Patterns/66666666-6666-4666-8666-666666666666"))
        let cachedURL = tempDirectory
            .appendingPathComponent("cache", isDirectory: true)
            .appendingPathComponent(localCopyPath)
        #expect(FileManager.default.fileExists(atPath: cachedURL.path))
    }

    @Test func fetchProjectsDownloadsPatternCopyDrawingWhenCacheIsMissing() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.projectsWithPatternCopyDrawingResponseJSON.utf8))
            }

            if callCount == 2 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/file")
                #expect(request.httpMethod == "GET")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/pdf"]
                )!
                return (response, Data("%PDF-1.4".utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/drawing")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/octet-stream"]
            )!
            return (response, Data("PKDRAWING".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )

        let project = try #require(try await repository.fetchProjects().first)
        let patternCopy = try #require(project.patternCopy)
        let drawingDataPath = try #require(patternCopy.drawingDataPath)

        #expect(callCount == 3)
        #expect(drawingDataPath.hasSuffix("drawing.pkdrawing"))
        let cachedURL = tempDirectory
            .appendingPathComponent("cache", isDirectory: true)
            .appendingPathComponent(drawingDataPath)
        #expect(try Data(contentsOf: cachedURL) == Data("PKDRAWING".utf8))
    }

    @Test func fetchProjectRequestsProjectEndpointAndReturnsNilForNotFound() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())")
            #expect(request.httpMethod == "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"PROJECT_NOT_FOUND","message":"Project not found."}"#.utf8)
            )
        }

        let repository = Self.makeRepository(session: session)

        let project = try await repository.fetchProject(id: projectID)

        #expect(project == nil)
    }

    @Test func saveNewProjectPostsProjectPayload() async throws {
        let project = Self.project(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == "11111111-1111-4111-8111-111111111111")
            #expect(object["name"] as? String == "Favorite Cardigan")
            #expect(object["status"] as? String == "WIP")
            #expect(object["isFavorite"] as? Bool == true)
            #expect(object["memo"] as? String == "Use smaller needles for ribbing.")
            #expect(object["targetDate"] as? String != nil)
            #expect(object["finishedAt"] == nil)
            #expect(object["yarnId"] as? String == "cccccccc-cccc-4ccc-8ccc-cccccccccccc")
            #expect(object["yarnNameSnapshot"] as? String == "Soft Merino DK")
            #expect(object["yarnBrandSnapshot"] as? String == "Sample Yarn Co.")
            #expect(object["yarnColorwaySnapshot"] as? String == "Cloud Gray")
            #expect(object["yarnWeightSnapshot"] as? String == "DK")
            #expect(object["needleId"] as? String == "dddddddd-dddd-4ddd-8ddd-dddddddddddd")
            #expect(object["needleNameSnapshot"] as? String == "Wood Circular Needle")
            #expect(object["needleTypeSnapshot"] as? String == "Circular")
            #expect(object["needleSizeSnapshot"] as? String == "5.0 mm")
            #expect(object["needleLengthSnapshot"] as? String == "80 cm")
            #expect(object["relatedSkillIds"] as? [String] == [
                "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            ])
            let rowCounter = try #require(object["rowCounter"] as? [String: Any])
            #expect(rowCounter["currentRow"] as? Int == 42)
            #expect(rowCounter["targetRow"] as? Int == 120)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveProject(project)
    }

    @Test func saveProjectIncludesPatternCopyPayload() async throws {
        let project = Self.project(
            syncStatus: .synced,
            patternCopy: Self.patternCopy()
        )
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111")
            #expect(request.httpMethod == "PATCH")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            let patternCopy = try #require(object["patternCopy"] as? [String: Any])
            #expect(patternCopy["id"] as? String == "66666666-6666-4666-8666-666666666666")
            #expect(patternCopy["projectId"] as? String == "11111111-1111-4111-8111-111111111111")
            #expect(patternCopy["sourcePatternDocumentId"] as? String == "44444444-4444-4444-8444-444444444444")
            #expect(patternCopy["titleSnapshot"] as? String == "Cozy Shawl")
            #expect(patternCopy["fileNameSnapshot"] as? String == "cozy-shawl.pdf")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectWithPatternCopyResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveProject(project)
    }

    @Test func saveProjectUploadsDirectPatternCopyFileAfterSavingProject() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let cacheRootURL = tempDirectory.appendingPathComponent("cache", isDirectory: true)
        let sourceURL = tempDirectory.appendingPathComponent("direct-cardigan.pdf")
        try Data("%PDF-1.4 direct".utf8).write(to: sourceURL)
        let fileStore = LocalPatternFileStore(rootDirectoryURL: cacheRootURL)
        let storedFile = try fileStore.storeProjectPatternFile(
            from: sourceURL,
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            copyId: UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
        )
        let project = Self.project(
            syncStatus: .localOnly,
            patternCopy: Self.directPatternCopy(localCopyPath: storedFile.relativePath)
        )
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
                #expect(request.httpMethod == "POST")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.projectResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/file")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#"filename="direct-cardigan.pdf""#))
            #expect(bodyString.contains("%PDF-1.4 direct"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.directPatternCopyResponseJSON.utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: cacheRootURL
        )

        try await repository.saveProject(project)

        #expect(callCount == 2)
    }

    @Test func saveProjectUploadsPatternCopyDrawingAfterSavingProject() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let cacheRootURL = tempDirectory.appendingPathComponent("cache", isDirectory: true)
        let fileStore = LocalPatternFileStore(rootDirectoryURL: cacheRootURL)
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let copyID = UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
        let drawingData = Data("PKDRAWING".utf8)
        let drawingPath = try fileStore.storeProjectPatternDrawingData(
            drawingData,
            projectId: projectID,
            copyId: copyID
        )
        let patternCopy = Self.patternCopy().copy(
            drawingDataPath: drawingPath,
            drawingUpdatedAt: Date(timeIntervalSince1970: 1_783_075_600),
            syncStatus: .localOnly
        )
        let project = Self.project(syncStatus: .localOnly, patternCopy: patternCopy)
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
                #expect(request.httpMethod == "POST")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.projectWithPatternCopyResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111/pattern-copy/drawing")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#"filename="drawing.pkdrawing""#))
            #expect(bodyString.contains("PKDRAWING"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.patternCopyWithDrawingResponseJSON.utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: cacheRootURL
        )

        try await repository.saveProject(project)

        #expect(callCount == 2)
    }

    @Test func saveSyncedProjectPatchesProjectPayload() async throws {
        let project = Self.project(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-4111-8111-111111111111")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        try await repository.saveProject(project)
    }

    /// 서버 updatedAt은 밀리초를 가진다. 저장 요청의 baseUpdatedAt이 초 단위로 잘리면
    /// 서버 낙관적 잠금이 실제 충돌이 아닌데 409(PROJECT_CONFLICT)를 낸다.
    /// 서버가 준 시각을 밀리초까지 그대로 되돌려 보내는지 확인한다.
    @Test func saveSyncedProjectSendsBaseUpdatedAtWithMilliseconds() async throws {
        let project = Self.project(syncStatus: .synced)
        let serverUpdatedAt = "2026-07-03T09:00:00.123Z"
        let responseJSON = Self.projectResponseJSON.replacingOccurrences(
            of: "\"updatedAt\": \"2026-07-03T09:00:00.000Z\"",
            with: "\"updatedAt\": \"\(serverUpdatedAt)\""
        )

        let session = MockURLProtocol.makeSession { request in
            if request.httpMethod == "PATCH" {
                let body = try Self.bodyData(from: request)
                let object = try #require(
                    JSONSerialization.jsonObject(with: body) as? [String: Any]
                )
                #expect(object["baseUpdatedAt"] as? String == serverUpdatedAt)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)

        _ = try await repository.fetchProject(id: project.id)
        try await repository.saveProject(project)
    }

    /// GitHub #14. 마지막으로 확인한 서버 updatedAt이 앱 재시작을 넘겨 남는지 본다.
    ///
    /// 이 값이 메모리에만 있으면 재시작 직후 첫 저장이 baseUpdatedAt 없이 나가고, 서버는
    /// 그 요청을 last-write-wins로 통과시킨다. 다른 기기가 고친 것을 만나는 상황은 대개 앱을
    /// 다시 켰을 때이므로 보호가 가장 필요한 순간에 꺼진다.
    ///
    /// 앞의 케이스와 갈리는 지점은 조회를 한 인스턴스와 저장을 하는 인스턴스가 다르다는 것이다.
    /// 같은 인스턴스에서 이어서 저장하면 메모리 값만으로도 통과해 이 결함이 보이지 않는다.
    @Test func baseUpdatedAtSurvivesRepositoryRecreation() async throws {
        let project = Self.project(syncStatus: .synced)
        let serverUpdatedAt = "2026-07-03T09:00:00.123Z"
        let responseJSON = Self.projectResponseJSON.replacingOccurrences(
            of: "\"updatedAt\": \"2026-07-03T09:00:00.000Z\"",
            with: "\"updatedAt\": \"\(serverUpdatedAt)\""
        )

        let suiteName = "KnitGetherTests.\(UUID().uuidString)"
        let store = try #require(UserDefaults(suiteName: suiteName))
        defer {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }

        let sentBaseUpdatedAt = SentValueRecorder()
        let session = MockURLProtocol.makeSession { request in
            if request.httpMethod == "PATCH" {
                let body = try Self.bodyData(from: request)
                let object = try #require(
                    JSONSerialization.jsonObject(with: body) as? [String: Any]
                )
                sentBaseUpdatedAt.record(object["baseUpdatedAt"] as? String)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }

        // 앱 실행 1. 조회만 하고 끝난다.
        let firstLaunch = Self.makeRepository(session: session, serverUpdatedAtStore: store)
        _ = try await firstLaunch.fetchProject(id: project.id)

        // 앱 실행 2. 조회 없이 곧바로 저장한다.
        let secondLaunch = Self.makeRepository(session: session, serverUpdatedAtStore: store)
        try await secondLaunch.saveProject(project)

        #expect(
            sentBaseUpdatedAt.value == serverUpdatedAt,
            "재시작 후 첫 저장이 baseUpdatedAt 없이 나갔다. 서버가 last-write-wins로 통과시킨다"
        )
    }

    @Test func deleteProjectRequestsProjectDeleteEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session)

        try await repository.deleteProject(id: projectID)
    }

    @Test func saveRowCounterPatchesPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let rowCounter = Self.rowCounter(currentRow: 43)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/row-counter")
            #expect(request.httpMethod == "PATCH")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == "22222222-2222-4222-8222-222222222222")
            #expect(object["projectId"] as? String == projectID.uuidString.lowercased())
            #expect(object["mode"] as? String == "rowGuide")
            #expect(object["currentRow"] as? Int == 43)
            #expect(object["targetRow"] as? Int == 120)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.rowCounterResponseJSON(currentRow: 43).utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedCounter = try await repository.saveRowCounter(rowCounter, forProjectId: projectID)

        #expect(savedCounter.currentRow == 43)
        #expect(savedCounter.syncStatus == .synced)
    }

    @Test func saveLocalOnlyRowInstructionPostsPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let instruction = Self.rowInstruction(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/row-instructions")
            #expect(request.httpMethod == "POST")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == "88888888-8888-4888-8888-888888888888")
            #expect(object["rowCounterId"] as? String == "22222222-2222-4222-8222-222222222222")
            #expect(object["rowNumber"] as? Int == 50)
            #expect(object["instructionText"] as? String == "P all stitches.")
            #expect(object["skillTags"] as? String == "P")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.rowInstructionResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedInstruction = try await repository.saveRowInstruction(instruction, forProjectId: projectID)

        #expect(savedInstruction.rowNumber == 50)
        #expect(savedInstruction.syncStatus == .synced)
    }

    @Test func saveSyncedRowInstructionPatchesPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let instruction = Self.rowInstruction(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/row-instructions/88888888-8888-4888-8888-888888888888")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.rowInstructionResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedInstruction = try await repository.saveRowInstruction(instruction, forProjectId: projectID)

        #expect(savedInstruction.id == instruction.id)
        #expect(savedInstruction.syncStatus == .synced)
    }

    @Test func deleteRowInstructionUsesPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let instructionID = UUID(uuidString: "88888888-8888-4888-8888-888888888888")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/row-instructions/\(instructionID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session)
        try await repository.deleteRowInstruction(id: instructionID, forProjectId: projectID)
    }

    @Test func saveLocalOnlyWorkSessionPostsPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let workSession = Self.workSession(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/work-sessions")
            #expect(request.httpMethod == "POST")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == "77777777-7777-4777-8777-777777777777")
            #expect(object["projectId"] as? String == projectID.uuidString.lowercased())
            #expect(object["startedAt"] as? String != nil)
            #expect(object["endedAt"] as? String != nil)
            #expect(object["memo"] as? String == "Sleeve increases.")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.workSessionResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedSession = try await repository.saveWorkSession(workSession, forProjectId: projectID)

        #expect(savedSession.memo == "Sleeve increases.")
        #expect(savedSession.syncStatus == .synced)
    }

    @Test func saveNewWorkSessionRecordedFromSyncedProjectPostsPartialEndpoint() async throws {
        let project = Self.project(syncStatus: .synced)
        let recordedProject = project.recordingWorkSession(
            startedAt: Self.date("2026-07-03T08:00:00.000Z"),
            endedAt: Self.date("2026-07-03T09:00:00.000Z")
        )
        let workSession = try #require(recordedProject.workSessions.last)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(project.id.uuidString.lowercased())/work-sessions")
            #expect(request.httpMethod == "POST")

            let body = try Self.bodyData(from: request)
            let object = try #require(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )
            #expect(object["id"] as? String == workSession.id.uuidString.lowercased())
            #expect(object["projectId"] as? String == project.id.uuidString.lowercased())

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.workSessionResponseJSON.utf8))
        }

        #expect(workSession.syncStatus == .localOnly)

        let repository = Self.makeRepository(session: session)
        let savedSession = try await repository.saveWorkSession(workSession, forProjectId: project.id)

        #expect(savedSession.syncStatus == .synced)
    }

    @Test func saveSyncedWorkSessionPatchesPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let workSession = Self.workSession(syncStatus: .synced)
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/work-sessions/77777777-7777-4777-8777-777777777777")
            #expect(request.httpMethod == "PATCH")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.workSessionResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let savedSession = try await repository.saveWorkSession(workSession, forProjectId: projectID)

        #expect(savedSession.id == workSession.id)
        #expect(savedSession.syncStatus == .synced)
    }

    @Test func deleteWorkSessionUsesPartialEndpoint() async throws {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let sessionID = UUID(uuidString: "77777777-7777-4777-8777-777777777777")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())/work-sessions/\(sessionID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session)
        try await repository.deleteWorkSession(id: sessionID, forProjectId: projectID)
    }

    private static func makeRepository(
        session: URLSession,
        cacheRootURL: URL? = nil,
        serverUpdatedAtStore: UserDefaults = .standard
    ) -> RemoteProjectRepository {
        RemoteProjectRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            ),
            fileStore: LocalPatternFileStore(
                fileManager: .default,
                rootDirectoryURL: cacheRootURL
            ),
            serverUpdatedAtStore: serverUpdatedAtStore
        )
    }

    private static func project(
        syncStatus: SyncStatus = .synced,
        patternCopy: ProjectPatternCopy? = nil
    ) -> KnittingProject {
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let now = Date(timeIntervalSince1970: 1_783_071_200)
        let targetDate = Self.date("2026-08-15T00:00:00.000Z")

        return KnittingProject(
            id: projectID,
            ownerId: "user-a",
            name: "Favorite Cardigan",
            status: .wip,
            isFavorite: true,
            memo: "Use smaller needles for ribbing.",
            startDate: now,
            targetDate: targetDate,
            finishedAt: nil,
            lastWorkedAt: now,
            patternCopy: patternCopy,
            yarnId: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
            yarnNameSnapshot: "Soft Merino DK",
            yarnBrandSnapshot: "Sample Yarn Co.",
            yarnColorwaySnapshot: "Cloud Gray",
            yarnWeightSnapshot: "DK",
            needleId: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            needleNameSnapshot: "Wood Circular Needle",
            needleTypeSnapshot: "Circular",
            needleSizeSnapshot: "5.0 mm",
            needleLengthSnapshot: "80 cm",
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: projectID,
                currentRow: 42,
                targetRow: 120,
                createdAt: now,
                updatedAt: now
            ),
            workSessions: [],
            relatedSkillIds: [UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!],
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func patternCopy() -> ProjectPatternCopy {
        let now = Date(timeIntervalSince1970: 1_783_071_200)

        return ProjectPatternCopy(
            id: UUID(uuidString: "66666666-6666-4666-8666-666666666666")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            sourcePatternDocumentId: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
            titleSnapshot: "Cozy Shawl",
            designerSnapshot: "Yu",
            fileNameSnapshot: "cozy-shawl.pdf",
            localCopyPath: "Projects/11111111-1111-4111-8111-111111111111/Patterns/66666666-6666-4666-8666-666666666666/cozy-shawl.pdf",
            pageCountSnapshot: 12,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func directPatternCopy(localCopyPath: String) -> ProjectPatternCopy {
        let now = Date(timeIntervalSince1970: 1_783_071_200)

        return ProjectPatternCopy(
            id: UUID(uuidString: "66666666-6666-4666-8666-666666666666")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            sourcePatternDocumentId: nil,
            titleSnapshot: "Direct Cardigan",
            designerSnapshot: nil,
            fileNameSnapshot: "direct-cardigan.pdf",
            localCopyPath: localCopyPath,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
    }

    private static func rowCounter(currentRow: Int) -> RowCounter {
        let now = Date(timeIntervalSince1970: 1_783_071_200)
        return RowCounter(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            name: "Main Counter",
            mode: .rowGuide,
            sectionName: "Sleeve",
            memo: "Check increases.",
            currentRow: currentRow,
            targetRow: 120,
            rowInstructions: [],
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func rowInstruction(syncStatus: SyncStatus) -> RowInstruction {
        let now = Date(timeIntervalSince1970: 1_783_071_200)
        return RowInstruction(
            id: UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            rowCounterId: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
            rowNumber: 50,
            instructionText: "P all stitches.",
            skillTags: "P",
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    private static func workSession(syncStatus: SyncStatus) -> WorkSession {
        let startedAt = date("2026-07-03T08:00:00.000Z")
        let endedAt = date("2026-07-03T09:00:00.000Z")
        return WorkSession(
            id: UUID(uuidString: "77777777-7777-4777-8777-777777777777")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            startedAt: startedAt,
            endedAt: endedAt,
            memo: "Sleeve increases.",
            createdAt: startedAt,
            updatedAt: endedAt,
            syncStatus: syncStatus
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteProjectRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func date(_ value: String) -> Date {
        fractionalISO8601Formatter.date(from: value)!
    }

    private static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func bodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let bodyStream = request.httpBodyStream else {
            Issue.record("Expected request body")
            return Data()
        }

        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        let bufferSize = 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while bodyStream.hasBytesAvailable {
            let readCount = bodyStream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if readCount == 0 {
                break
            }
            data.append(buffer, count: readCount)
        }

        return data
    }

    private static func rowCounterResponseJSON(currentRow: Int) -> String {
        """
        {
          "id": "22222222-2222-4222-8222-222222222222",
          "ownerId": "user-a",
          "projectId": "11111111-1111-4111-8111-111111111111",
          "name": "Main Counter",
          "mode": "rowGuide",
          "sectionName": "Sleeve",
          "memo": "Check increases.",
          "currentRow": \(currentRow),
          "targetRow": 120,
          "rowInstructions": [],
          "createdAt": "2026-07-01T00:00:00.000Z",
          "updatedAt": "2026-07-03T09:00:00.000Z",
          "deletedAt": null,
          "syncStatus": "Synced"
        }
        """
    }

    private static let rowInstructionResponseJSON = """
    {
      "id": "88888888-8888-4888-8888-888888888888",
      "ownerId": "user-a",
      "projectId": "11111111-1111-4111-8111-111111111111",
      "rowCounterId": "22222222-2222-4222-8222-222222222222",
      "rowNumber": 50,
      "instructionText": "P all stitches.",
      "skillTags": "P",
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let workSessionResponseJSON = """
    {
      "id": "77777777-7777-4777-8777-777777777777",
      "ownerId": "user-a",
      "projectId": "11111111-1111-4111-8111-111111111111",
      "startedAt": "2026-07-03T08:00:00.000Z",
      "endedAt": "2026-07-03T09:00:00.000Z",
      "memo": "Sleeve increases.",
      "createdAt": "2026-07-03T08:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectResponseJSON = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "ownerId": "user-a",
      "name": "Favorite Cardigan",
      "status": "WIP",
      "isFavorite": true,
      "memo": "Use smaller needles for ribbing.",
      "startDate": "2026-07-01T00:00:00.000Z",
      "targetDate": "2026-08-15T00:00:00.000Z",
      "finishedAt": null,
      "lastWorkedAt": "2026-07-03T09:00:00.000Z",
      "patternCopy": null,
      "yarnId": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
      "yarnNameSnapshot": "Soft Merino DK",
      "yarnBrandSnapshot": "Sample Yarn Co.",
      "yarnColorwaySnapshot": "Cloud Gray",
      "yarnWeightSnapshot": "DK",
      "needleId": "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
      "needleNameSnapshot": "Wood Circular Needle",
      "needleTypeSnapshot": "Circular",
      "needleSizeSnapshot": "5.0 mm",
      "needleLengthSnapshot": "80 cm",
      "workspaceDisplayMode": "patternAndCounter",
      "workspaceSheetPosition": "medium",
      "rowCounter": {
        "id": "22222222-2222-4222-8222-222222222222",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "name": "Main Counter",
        "currentRow": 42,
        "targetRow": 120,
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "workSessions": [],
      "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectWithPatternCopyResponseJSON = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "ownerId": "user-a",
      "name": "Favorite Cardigan",
      "status": "WIP",
      "isFavorite": true,
      "memo": "Use smaller needles for ribbing.",
      "startDate": "2026-07-01T00:00:00.000Z",
      "targetDate": "2026-08-15T00:00:00.000Z",
      "finishedAt": null,
      "lastWorkedAt": "2026-07-03T09:00:00.000Z",
      "patternCopy": {
        "id": "66666666-6666-4666-8666-666666666666",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "sourcePatternDocumentId": "44444444-4444-4444-8444-444444444444",
        "titleSnapshot": "Cozy Shawl",
        "designerSnapshot": "Yu",
        "fileNameSnapshot": "cozy-shawl.pdf",
        "localCopyPath": null,
        "pageCountSnapshot": 12,
        "drawingDataPath": null,
        "drawingUpdatedAt": null,
        "copiedAt": "2026-07-04T12:00:00.000Z",
        "createdAt": "2026-07-04T12:00:00.000Z",
        "updatedAt": "2026-07-05T12:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "yarnId": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
      "yarnNameSnapshot": "Soft Merino DK",
      "yarnBrandSnapshot": "Sample Yarn Co.",
      "yarnColorwaySnapshot": "Cloud Gray",
      "yarnWeightSnapshot": "DK",
      "needleId": "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
      "needleNameSnapshot": "Wood Circular Needle",
      "needleTypeSnapshot": "Circular",
      "needleSizeSnapshot": "5.0 mm",
      "needleLengthSnapshot": "80 cm",
      "workspaceDisplayMode": "patternAndCounter",
      "workspaceSheetPosition": "medium",
      "rowCounter": {
        "id": "22222222-2222-4222-8222-222222222222",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "name": "Main Counter",
        "currentRow": 42,
        "targetRow": 120,
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "workSessions": [],
      "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectWithPatternCopyDrawingResponseJSON = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "ownerId": "user-a",
      "name": "Favorite Cardigan",
      "status": "WIP",
      "isFavorite": true,
      "memo": "Use smaller needles for ribbing.",
      "startDate": "2026-07-01T00:00:00.000Z",
      "targetDate": "2026-08-15T00:00:00.000Z",
      "finishedAt": null,
      "lastWorkedAt": "2026-07-03T09:00:00.000Z",
      "patternCopy": {
        "id": "66666666-6666-4666-8666-666666666666",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "sourcePatternDocumentId": "44444444-4444-4444-8444-444444444444",
        "titleSnapshot": "Cozy Shawl",
        "designerSnapshot": "Yu",
        "fileNameSnapshot": "cozy-shawl.pdf",
        "localCopyPath": null,
        "pageCountSnapshot": 12,
        "drawingDataPath": null,
        "drawingUpdatedAt": "2026-07-05T13:00:00.000Z",
        "copiedAt": "2026-07-04T12:00:00.000Z",
        "createdAt": "2026-07-04T12:00:00.000Z",
        "updatedAt": "2026-07-05T12:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "yarnId": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
      "yarnNameSnapshot": "Soft Merino DK",
      "yarnBrandSnapshot": "Sample Yarn Co.",
      "yarnColorwaySnapshot": "Cloud Gray",
      "yarnWeightSnapshot": "DK",
      "needleId": "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
      "needleNameSnapshot": "Wood Circular Needle",
      "needleTypeSnapshot": "Circular",
      "needleSizeSnapshot": "5.0 mm",
      "needleLengthSnapshot": "80 cm",
      "workspaceDisplayMode": "patternAndCounter",
      "workspaceSheetPosition": "medium",
      "rowCounter": {
        "id": "22222222-2222-4222-8222-222222222222",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "name": "Main Counter",
        "currentRow": 42,
        "targetRow": 120,
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "workSessions": [],
      "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let directPatternCopyResponseJSON = """
    {
      "id": "66666666-6666-4666-8666-666666666666",
      "ownerId": "user-a",
      "projectId": "11111111-1111-4111-8111-111111111111",
      "sourcePatternDocumentId": null,
      "titleSnapshot": "Direct Cardigan",
      "designerSnapshot": null,
      "fileNameSnapshot": "direct-cardigan.pdf",
      "localCopyPath": null,
      "pageCountSnapshot": null,
      "drawingDataPath": null,
      "drawingUpdatedAt": null,
      "copiedAt": "2026-07-04T12:00:00.000Z",
      "createdAt": "2026-07-04T12:00:00.000Z",
      "updatedAt": "2026-07-05T12:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let patternCopyWithDrawingResponseJSON = """
    {
      "id": "66666666-6666-4666-8666-666666666666",
      "ownerId": "user-a",
      "projectId": "11111111-1111-4111-8111-111111111111",
      "sourcePatternDocumentId": "44444444-4444-4444-8444-444444444444",
      "titleSnapshot": "Cozy Shawl",
      "designerSnapshot": "Yu",
      "fileNameSnapshot": "cozy-shawl.pdf",
      "localCopyPath": null,
      "pageCountSnapshot": 12,
      "drawingDataPath": null,
      "drawingUpdatedAt": "2026-07-05T13:00:00.000Z",
      "copiedAt": "2026-07-04T12:00:00.000Z",
      "createdAt": "2026-07-04T12:00:00.000Z",
      "updatedAt": "2026-07-05T12:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectsResponseJSON = """
    [
      {
        "id": "11111111-1111-4111-8111-111111111111",
        "ownerId": "user-a",
        "name": "Favorite Cardigan",
        "status": "WIP",
        "isFavorite": true,
        "memo": "Use smaller needles for ribbing.",
        "startDate": "2026-07-01T00:00:00.000Z",
        "targetDate": "2026-08-15T00:00:00.000Z",
        "finishedAt": null,
        "lastWorkedAt": "2026-07-03T09:00:00.000Z",
        "patternCopy": null,
        "yarnId": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        "yarnNameSnapshot": "Soft Merino DK",
        "yarnBrandSnapshot": "Sample Yarn Co.",
        "yarnColorwaySnapshot": "Cloud Gray",
        "yarnWeightSnapshot": "DK",
        "needleId": "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
        "needleNameSnapshot": "Wood Circular Needle",
        "needleTypeSnapshot": "Circular",
        "needleSizeSnapshot": "5.0 mm",
        "needleLengthSnapshot": "80 cm",
        "workspaceDisplayMode": "patternAndCounter",
        "workspaceSheetPosition": "medium",
        "rowCounter": {
          "id": "22222222-2222-4222-8222-222222222222",
          "ownerId": "user-a",
          "projectId": "11111111-1111-4111-8111-111111111111",
          "name": "Main Counter",
          "currentRow": 42,
          "targetRow": 120,
          "createdAt": "2026-07-01T00:00:00.000Z",
          "updatedAt": "2026-07-03T09:00:00.000Z",
          "deletedAt": null,
          "syncStatus": "Synced"
        },
        "workSessions": [
          {
            "id": "33333333-3333-4333-8333-333333333333",
            "ownerId": "user-a",
            "projectId": "11111111-1111-4111-8111-111111111111",
            "startedAt": "2026-07-03T08:00:00.000Z",
            "endedAt": "2026-07-03T09:00:00.000Z",
            "memo": "Sleeve increases.",
            "createdAt": "2026-07-03T09:00:00.000Z",
            "updatedAt": "2026-07-03T09:00:00.000Z",
            "deletedAt": null,
            "syncStatus": "Synced"
          }
        ],
        "relatedSkillIds": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"],
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-03T09:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      }
    ]
    """

    private static let projectsWithPatternCopyResponseJSON = """
    [
      \(projectWithPatternCopyResponseJSON)
    ]
    """

    private static let projectsWithPatternCopyDrawingResponseJSON = """
    [
      \(projectWithPatternCopyDrawingResponseJSON)
    ]
    """
}

/// 요청 본문에서 뽑은 값을 테스트 본체로 넘긴다.
/// MockURLProtocol 핸들러가 다른 스레드에서 돌아 잠금을 쓴다.
private final class SentValueRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?

    var value: String? {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func record(_ newValue: String?) {
        lock.lock()
        defer { lock.unlock() }
        _value = newValue
    }
}
