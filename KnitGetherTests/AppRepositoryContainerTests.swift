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

    @Test func makeDefaultUsesRemoteRepositoriesWhenAPIBaseURLIsConfigured() async throws {
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
        #expect(container.projectRepository is RemoteProjectRepository)
        #expect(container.patternRepository is RemotePatternRepository)
        #expect(container.gaugeRecordRepository is RemoteGaugeRecordRepository)
        #expect(container.gaugeTargetRepository is RemoteGaugeTargetRepository)
        #expect(container.libraryRepository is RemoteLibraryRepository)
        #expect(container.skillRepository is RemoteSkillRepository)
        #expect(container.profileRepository is RemoteProfileRepository)

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

    @Test func remoteModeDoesNotCreateJSONDataCachesPerAccount() async throws {
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

        #expect(jsonCachePaths.isEmpty)
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

        #expect(jsonCachePaths.isEmpty)
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
}
