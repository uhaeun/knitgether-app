import Foundation
import Testing
@testable import KnitGether

@MainActor
struct AppRepositoryContainerTests {
    @Test func makeDefaultUsesLocalRepositoriesWhenAPIBaseURLIsMissing() {
        let container = AppRepositoryContainer.makeDefault(
            environment: [:],
            authSessionStore: Self.makeEmptySessionStore()
        )

        #expect(container.authRepository is LocalAuthRepository)
        #expect(container.projectRepository is LocalProjectRepository)
        #expect(container.patternRepository is LocalPatternRepository)
        #expect(container.gaugeRecordRepository is LocalGaugeRecordRepository)
        #expect(container.gaugeTargetRepository is LocalGaugeTargetRepository)
        #expect(container.libraryRepository is LocalLibraryRepository)
        #expect(container.skillRepository is LocalSkillRepository)
        #expect(container.profileRepository is LocalProfileRepository)
    }

    @Test func makeDefaultUsesOfflineFirstRepositoriesWhenAPIBaseURLIsConfigured() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects" {
                return (response, Data("[]".utf8))
            }

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/skills" {
                return (response, Data("[]".utf8))
            }

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/library/yarns" {
                return (response, Data("[]".utf8))
            }

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/library/needles" {
                return (response, Data("[]".utf8))
            }

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/profile" {
                return (response, Data(Self.profileJSON.utf8))
            }

            #expect(request.url?.absoluteString == "https://api.knitgether.test/api/v1/patterns")
            return (response, Data("[]".utf8))
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_DEV_AUTH_TOKEN": "dev-token",
                "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
            ],
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )

        #expect(container.authRepository is RemoteAuthRepository)
        #expect(container.projectRepository is OfflineFirstProjectRepository)
        #expect(container.patternRepository is OfflineFirstPatternRepository)
        #expect(container.gaugeRecordRepository is OfflineFirstGaugeRecordRepository)
        #expect(container.gaugeTargetRepository is RemoteGaugeTargetRepository)
        #expect(container.progressPhotoRepository is RemoteProjectProgressPhotoRepository)
        #expect(container.libraryRepository is OfflineFirstLibraryRepository)
        #expect(container.skillRepository is OfflineFirstSkillRepository)
        #expect(container.dictionaryRepository is OfflineFirstDictionaryRepository)
        #expect(container.profileRepository is OfflineFirstProfileRepository)

        let projects = try await container.projectRepository.fetchProjects()
        #expect(projects.isEmpty)

        let patterns = try await container.patternRepository.fetchPatterns()
        #expect(patterns.isEmpty)

        let skills = try await container.skillRepository.fetchSkills()
        #expect(skills.isEmpty)

        let yarns = try await container.libraryRepository.fetchYarns()
        #expect(yarns.isEmpty)

        let needles = try await container.libraryRepository.fetchNeedles()
        #expect(needles.isEmpty)

        let profile = try await container.profileRepository.fetchCurrentProfile()
        #expect(profile.id == "user-a")
    }

    @Test func apiModeSignedOutProfileRepositoryUsesAnonymousLocalCache() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        var remoteRequestCount = 0
        let session = MockURLProtocol.makeSession { request in
            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/profile" {
                remoteRequestCount += 1
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"UNAUTHENTICATED","message":"Missing token."}"#.utf8)
            )
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )

        #expect(container.profileRepository is LocalProfileRepository)

        let profile = Self.makeUserProfile(syncStatus: .localOnly)
        try await container.profileRepository.saveCurrentProfile(profile)

        let restoredContainer = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )
        let restoredProfile = try await restoredContainer.profileRepository.fetchCurrentProfile()

        #expect(restoredProfile.displayName == "Local Knitter")
        #expect(restoredProfile.syncStatus == .localOnly)
        #expect(remoteRequestCount == 0)
    }

    @Test func apiModeProjectRepositoryCachesRemoteProjectsAndFallsBackToCacheWhenServerFails() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let successSession = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.projectsJSON.utf8))
        }

        let firstContainer = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: successSession,
            authSessionStore: Self.makeEmptySessionStore()
        )

        let remoteProjects = try await firstContainer.projectRepository.fetchProjects()
        #expect(remoteProjects.map(\.name) == ["Favorite Cardigan"])

        let failingSession = MockURLProtocol.makeSession { _ in
            throw URLError(.notConnectedToInternet)
        }
        let secondContainer = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: failingSession,
            authSessionStore: Self.makeEmptySessionStore()
        )

        let cachedProjects = try await secondContainer.projectRepository.fetchProjects()

        #expect(cachedProjects.map(\.name) == ["Favorite Cardigan"])
        #expect(cachedProjects.map(\.syncStatus) == [.synced])
    }

    @Test func apiModeProjectWriteRetryableFailurePreservesPendingAndSyncsAfterNetworkRecovery() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        var shouldFailSaves = true
        var savedProjectIDs: [UUID] = []
        let project = Self.makeProject(syncStatus: .localOnly)
        let session = MockURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects",
               request.httpMethod == "POST" {
                if shouldFailSaves {
                    let failedResponse = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 503,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (
                        failedResponse,
                        Data(#"{"code":"TEMPORARY_UNAVAILABLE","message":"Try later."}"#.utf8)
                    )
                }

                savedProjectIDs.append(project.id)
                return (response, Data(Self.projectJSON.utf8))
            }

            if request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects/\(project.id.uuidString.lowercased())" {
                return (response, Data(Self.projectJSON.utf8))
            }

            #expect(request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects")
            return (response, Data(Self.projectsJSON.utf8))
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )

        try await container.projectRepository.saveProject(project)

        let pendingProjects = try Self.cachedProjects(in: cacheDirectory)
        #expect(pendingProjects.map(\.syncStatus) == [.localOnly])
        #expect(savedProjectIDs.isEmpty)

        shouldFailSaves = false
        _ = try await container.projectRepository.fetchProjects()

        #expect(savedProjectIDs == [project.id])
        #expect(try Self.cachedProjects(in: cacheDirectory).map(\.syncStatus) == [.synced])
    }

    @Test func apiModeProjectFetchWithoutServerAndWithoutCacheThrowsOfflineError() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let session = MockURLProtocol.makeSession { _ in
            throw URLError(.notConnectedToInternet)
        }
        let container = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(cacheDirectory: cacheDirectory),
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )

        do {
            _ = try await container.projectRepository.fetchProjects()
            Issue.record("Expected offline project fetch without local cache to throw")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }

    @Test func makeDefaultUsesAPIAuthTokenWhenConfigured() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer api-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_API_AUTH_TOKEN": "api-token",
                "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
            ],
            session: session,
            authSessionStore: Self.makeEmptySessionStore()
        )

        _ = try await container.projectRepository.fetchProjects()
    }

    @Test func makeDefaultUsesStoredSessionTokenBeforeDevToken() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let authSessionStore = Self.makeEmptySessionStore()
        try authSessionStore.save(Self.makeAuthSession())

        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_DEV_AUTH_TOKEN": "dev-token",
                "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
            ],
            session: session,
            authSessionStore: authSessionStore
        )

        _ = try await container.projectRepository.fetchProjects()
    }

    @Test func apiModeCreatesJSONDataCachesPerAccount() async throws {
        let cacheRootDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheRootDirectory) }
        let session = MockURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        let firstStore = Self.makeEmptySessionStore()
        try firstStore.save(Self.makeAuthSession(userId: "user-a", accessToken: "token-a"))
        let firstContainer = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY": cacheRootDirectory.path,
            ],
            session: session,
            authSessionStore: firstStore
        )
        _ = try await firstContainer.projectRepository.fetchProjects()

        let secondStore = Self.makeEmptySessionStore()
        try secondStore.save(Self.makeAuthSession(userId: "user-b", accessToken: "token-b"))
        let secondContainer = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY": cacheRootDirectory.path,
            ],
            session: session,
            authSessionStore: secondStore
        )
        _ = try await secondContainer.projectRepository.fetchProjects()

        let jsonCachePaths = try Self.filePaths(
            matchingExtension: "json",
            under: cacheRootDirectory
        )

        #expect(jsonCachePaths.contains { $0.contains("user-a") && $0.hasSuffix("projects.json") })
        #expect(jsonCachePaths.contains { $0.contains("user-b") && $0.hasSuffix("projects.json") })
    }

    @Test func apiModeCacheScopeSeparatesBaseURLAndUser() async throws {
        let cacheRootDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheRootDirectory) }
        let session = MockURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        let firstStore = Self.makeEmptySessionStore()
        try firstStore.save(Self.makeAuthSession(userId: "user-a", accessToken: "token-a"))
        let firstContainer = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(
                baseURL: "https://api.knitgether.test/api/v1",
                cacheRootDirectory: cacheRootDirectory
            ),
            session: session,
            authSessionStore: firstStore
        )
        _ = try await firstContainer.projectRepository.fetchProjects()

        let secondStore = Self.makeEmptySessionStore()
        try secondStore.save(Self.makeAuthSession(userId: "user-a", accessToken: "token-a"))
        let secondContainer = AppRepositoryContainer.makeDefault(
            environment: Self.apiEnvironment(
                baseURL: "https://staging.knitgether.test/api/v1",
                cacheRootDirectory: cacheRootDirectory
            ),
            session: session,
            authSessionStore: secondStore
        )
        _ = try await secondContainer.projectRepository.fetchProjects()

        let jsonCachePaths = try Self.filePaths(
            matchingExtension: "json",
            under: cacheRootDirectory
        )

        #expect(jsonCachePaths.contains { $0.contains("api-knitgether-test") && $0.contains("user-a") })
        #expect(jsonCachePaths.contains { $0.contains("staging-knitgether-test") && $0.contains("user-a") })
    }

    @Test func repositoryStoreRebuildsContainerWhenStoredAccountChanges() async throws {
        let cacheRootDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheRootDirectory) }
        let authSessionStore = Self.makeEmptySessionStore()
        try authSessionStore.save(Self.makeAuthSession(userId: "user-a", accessToken: "token-a"))

        let session = MockURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        let store = AppRepositoryStore(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY": cacheRootDirectory.path,
            ],
            session: session,
            authSessionStore: authSessionStore
        )
        let firstContainerID = store.container.instanceID
        _ = try await store.container.projectRepository.fetchProjects()

        try authSessionStore.save(Self.makeAuthSession(userId: "user-b", accessToken: "token-b"))
        try await Self.waitUntil {
            store.container.instanceID != firstContainerID
        }
        _ = try await store.container.projectRepository.fetchProjects()

        let jsonCachePaths = try Self.filePaths(
            matchingExtension: "json",
            under: cacheRootDirectory
        )

        #expect(jsonCachePaths.contains { $0.contains("user-a") && $0.hasSuffix("projects.json") })
        #expect(jsonCachePaths.contains { $0.contains("user-b") && $0.hasSuffix("projects.json") })

        let secondContainerID = store.container.instanceID
        try authSessionStore.clear()
        try await Self.waitUntil {
            store.container.instanceID != secondContainerID
        }
        _ = try await store.container.projectRepository.fetchProjects()

        let pathsAfterLogout = try Self.filePaths(
            matchingExtension: "json",
            under: cacheRootDirectory
        )
        #expect(pathsAfterLogout.contains { $0.contains("anonymous") && $0.hasSuffix("projects.json") })
    }

    @Test func unauthorizedResponseClearsStoredSessionToken() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let authSessionStore = Self.makeEmptySessionStore()
        try authSessionStore.save(Self.makeAuthSession())

        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"UNAUTHENTICATED","message":"Token expired."}"#.utf8)
            )
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_DEV_AUTH_TOKEN": "dev-token",
                "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
            ],
            session: session,
            authSessionStore: authSessionStore
        )

        do {
            _ = try await container.projectRepository.fetchProjects()
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 401)
            #expect(error.code == "UNAUTHENTICATED")
        }

        #expect(authSessionStore.currentSession == nil)
        #expect(authSessionStore.accessToken() == nil)
    }

    @Test func unauthorizedExplicitAPIAuthTokenDoesNotClearStoredSession() async throws {
        let cacheDirectory = try Self.makeTempCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let authSessionStore = Self.makeEmptySessionStore()
        try authSessionStore.save(Self.makeAuthSession())

        let session = MockURLProtocol.makeSession { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer api-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"UNAUTHENTICATED","message":"Token expired."}"#.utf8)
            )
        }

        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "https://api.knitgether.test/api/v1",
                "KNITGETHER_API_AUTH_TOKEN": "api-token",
                "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
            ],
            session: session,
            authSessionStore: authSessionStore
        )

        do {
            _ = try await container.projectRepository.fetchProjects()
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 401)
            #expect(error.code == "UNAUTHENTICATED")
        }

        #expect(authSessionStore.currentSession?.accessToken == "jwt-token")
        #expect(authSessionStore.accessToken() == "jwt-token")
    }

    private static func makeEmptySessionStore() -> AuthSessionStore {
        let suiteName = "AppRepositoryContainerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        return AuthSessionStore(
            userDefaults: defaults,
            tokenStorage: InMemoryAuthTokenStorage()
        )
    }

    private static func makeTempCacheDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppRepositoryContainerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func apiEnvironment(
        baseURL: String = "https://api.knitgether.test/api/v1",
        cacheDirectory: URL
    ) -> [String: String] {
        [
            "KNITGETHER_API_BASE_URL": baseURL,
            "KNITGETHER_LOCAL_CACHE_DIRECTORY": cacheDirectory.path,
        ]
    }

    private static func apiEnvironment(
        baseURL: String = "https://api.knitgether.test/api/v1",
        cacheRootDirectory: URL
    ) -> [String: String] {
        [
            "KNITGETHER_API_BASE_URL": baseURL,
            "KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY": cacheRootDirectory.path,
        ]
    }

    private static func cachedProjects(in cacheDirectory: URL) throws -> [KnittingProject] {
        let data = try Data(contentsOf: cacheDirectory.appendingPathComponent("projects.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([KnittingProject].self, from: data)
    }

    private static func makeProject(syncStatus: SyncStatus) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        let id = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        return KnittingProject(
            id: id,
            ownerId: "user-a",
            name: "Favorite Cardigan",
            status: .wip,
            isFavorite: true,
            memo: "Use smaller needles for ribbing.",
            startDate: now,
            targetDate: nil,
            finishedAt: nil,
            lastWorkedAt: nil,
            patternCopy: nil,
            rowCounter: RowCounter(
                ownerId: "user-a",
                projectId: id,
                currentRow: 0,
                targetRow: nil,
                createdAt: now,
                updatedAt: now,
                syncStatus: syncStatus
            ),
            workSessions: [],
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeUserProfile(syncStatus: SyncStatus) -> UserProfile {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return UserProfile(
            id: "user-a",
            ownerId: "user-a",
            displayName: "Local Knitter",
            preferredUnits: "Metric",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeAuthSession(
        userId: String = "user-a",
        accessToken: String = "jwt-token"
    ) -> AuthSession {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return AuthSession(
            accessToken: accessToken,
            tokenType: "Bearer",
            profile: UserProfile(
                id: userId,
                ownerId: userId,
                displayName: "Yuha",
                preferredUnits: "Metric",
                createdAt: now,
                updatedAt: now,
                deletedAt: nil,
                syncStatus: .synced
            )
        )
    }

    private static func filePaths(
        matchingExtension pathExtension: String,
        under directoryURL: URL
    ) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == pathExtension }
            .map(\.path)
            .sorted()
    }

    private static func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let start = ContinuousClock.now
        while !condition() {
            if start.duration(to: .now) > .nanoseconds(Int64(timeoutNanoseconds)) {
                Issue.record("Timed out waiting for condition")
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private static let profileJSON = """
    {
      "id":"user-a",
      "ownerId":"user-a",
      "displayName":"Local Knitter",
      "preferredUnits":"Metric",
      "createdAt":"2026-07-09T02:00:00.000Z",
      "updatedAt":"2026-07-09T02:05:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }
    """

    private static let projectJSON = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "ownerId": "user-a",
      "name": "Favorite Cardigan",
      "status": "WIP",
      "isFavorite": true,
      "memo": "Use smaller needles for ribbing.",
      "startDate": "2026-07-01T00:00:00.000Z",
      "targetDate": null,
      "finishedAt": null,
      "lastWorkedAt": null,
      "patternCopy": null,
      "workspaceDisplayMode": "counterOnly",
      "workspaceSheetPosition": "medium",
      "rowCounter": {
        "id": "22222222-2222-4222-8222-222222222222",
        "ownerId": "user-a",
        "projectId": "11111111-1111-4111-8111-111111111111",
        "name": "Main Counter",
        "currentRow": 0,
        "targetRow": null,
        "createdAt": "2026-07-01T00:00:00.000Z",
        "updatedAt": "2026-07-01T00:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      },
      "workSessions": [],
      "relatedSkillIds": [],
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-01T00:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let projectsJSON = """
    [
      \(projectJSON)
    ]
    """
}
