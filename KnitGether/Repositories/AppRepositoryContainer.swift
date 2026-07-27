//
//  AppRepositoryContainer.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

@MainActor
final class AppRepositoryContainer {
    static let shared = AppRepositoryContainer.makeDefault()

    let instanceID = UUID()

    let authRepository: any AuthRepository
    let authSessionStore: AuthSessionStore
    let projectRepository: any ProjectRepository
    let patternRepository: any PatternRepository
    let gaugeRecordRepository: any GaugeRecordRepository
    let gaugeTargetRepository: any GaugeTargetRepository
    let progressPhotoRepository: any ProjectProgressPhotoRepository
    let libraryRepository: any LibraryRepository
    let skillRepository: any SkillRepository
    let dictionaryRepository: any DictionaryRepository
    let profileRepository: any ProfileRepository
    let profileRequiresAuthentication: Bool

    init(
        authRepository: any AuthRepository,
        authSessionStore: AuthSessionStore,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        gaugeRecordRepository: any GaugeRecordRepository,
        gaugeTargetRepository: any GaugeTargetRepository,
        progressPhotoRepository: any ProjectProgressPhotoRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository,
        profileRepository: any ProfileRepository,
        profileRequiresAuthentication: Bool = false
    ) {
        self.authRepository = authRepository
        self.authSessionStore = authSessionStore
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.gaugeRecordRepository = gaugeRecordRepository
        self.gaugeTargetRepository = gaugeTargetRepository
        self.progressPhotoRepository = progressPhotoRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.dictionaryRepository = dictionaryRepository
        self.profileRepository = profileRepository
        self.profileRequiresAuthentication = profileRequiresAuthentication
    }

    static func makeDefault(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        session: URLSession = .shared
    ) -> AppRepositoryContainer {
        makeDefault(
            environment: environment,
            session: session,
            authSessionStore: .shared
        )
    }

    static func makeDefault(
        environment: [String: String],
        authSessionStore: AuthSessionStore
    ) -> AppRepositoryContainer {
        makeDefault(
            environment: environment,
            session: .shared,
            authSessionStore: authSessionStore
        )
    }

    static func makeDefault(
        environment: [String: String],
        session: URLSession,
        authSessionStore: AuthSessionStore
    ) -> AppRepositoryContainer {
        let authRepository: any AuthRepository
        let projectRepository: any ProjectRepository
        let patternRepository: any PatternRepository
        let gaugeRecordRepository: any GaugeRecordRepository
        let gaugeTargetRepository: any GaugeTargetRepository
        let progressPhotoRepository: any ProjectProgressPhotoRepository
        let libraryRepository: any LibraryRepository
        let skillRepository: any SkillRepository
        let dictionaryRepository: any DictionaryRepository
        let profileRepository: any ProfileRepository
        let profileRequiresAuthentication: Bool

        if let baseURL = apiBaseURL(from: environment) {
            let apiToken = apiAuthToken(from: environment)
            let devToken = devAuthToken(from: environment)
            let hasStaticAuthToken = apiToken != nil || devToken != nil
            let cacheDirectoryURL = remoteCacheDirectoryURL(
                from: environment,
                baseURL: baseURL,
                userId: authSessionStore.currentSession?.profile.ownerId
                    ?? authSessionStore.currentSession?.profile.id
            )

            let apiClient = APIClient(
                configuration: APIConfiguration(
                    baseURL: baseURL,
                    authTokenProvider: {
                        if let apiToken, !apiToken.isEmpty {
                            return apiToken
                        }

                        if let sessionToken = await authSessionStore.accessToken(),
                           !sessionToken.isEmpty {
                            return sessionToken
                        }

                        return devToken
                    },
                    authFailureHandler: {
                        guard apiToken == nil else {
                            return
                        }

                        await MainActor.run {
                            try? authSessionStore.clear()
                        }
                    }
                ),
                session: session
            )
            authRepository = RemoteAuthRepository(apiClient: apiClient)
            let patternFileStore = LocalPatternFileStore(
                rootDirectoryURL: cacheDirectoryURL.appendingPathComponent("pattern-files", isDirectory: true)
            )
            projectRepository = OfflineFirstProjectRepository(
                local: LocalProjectRepository(
                    seedSamples: false,
                    fileURL: cacheFileURL("projects.json", in: cacheDirectoryURL)
                ),
                remote: RemoteProjectRepository(
                    apiClient: apiClient,
                    fileStore: patternFileStore
                )
            )
            patternRepository = OfflineFirstPatternRepository(
                local: LocalPatternRepository(
                    seedSamples: false,
                    fileURL: cacheFileURL("patterns.json", in: cacheDirectoryURL),
                    fileStore: patternFileStore
                ),
                remote: RemotePatternRepository(
                    apiClient: apiClient,
                    fileStore: patternFileStore
                )
            )
            gaugeRecordRepository = OfflineFirstGaugeRecordRepository(
                local: LocalGaugeRecordRepository(
                    fileURL: cacheFileURL("gauge-records.json", in: cacheDirectoryURL)
                ),
                remote: RemoteGaugeRecordRepository(apiClient: apiClient)
            )
            gaugeTargetRepository = RemoteGaugeTargetRepository(apiClient: apiClient)
            let progressPhotoFileStore = LocalProjectProgressPhotoFileStore(
                rootDirectoryURL: cacheDirectoryURL.appendingPathComponent("progress-photos", isDirectory: true)
            )
            progressPhotoRepository = RemoteProjectProgressPhotoRepository(
                apiClient: apiClient,
                fileStore: progressPhotoFileStore
            )
            libraryRepository = OfflineFirstLibraryRepository(
                local: LocalLibraryRepository(
                    seedSamples: false,
                    fileURL: cacheFileURL("library.json", in: cacheDirectoryURL)
                ),
                remote: RemoteLibraryRepository(apiClient: apiClient)
            )
            skillRepository = OfflineFirstSkillRepository(
                local: LocalSkillRepository(
                    seedSamples: false,
                    fileURL: cacheFileURL("skills.json", in: cacheDirectoryURL)
                ),
                remote: RemoteSkillRepository(apiClient: apiClient)
            )
            dictionaryRepository = OfflineFirstDictionaryRepository(
                local: LocalDictionaryRepository(
                    seedSamples: false,
                    fileURL: cacheFileURL("dictionary-terms.json", in: cacheDirectoryURL)
                ),
                remote: RemoteDictionaryRepository(apiClient: apiClient)
            )
            let localProfileRepository = LocalProfileRepository(
                seedSample: false,
                fileURL: cacheFileURL("profile.json", in: cacheDirectoryURL)
            )
            if hasStaticAuthToken || authSessionStore.currentSession != nil {
                profileRepository = OfflineFirstProfileRepository(
                    local: localProfileRepository,
                    remote: RemoteProfileRepository(apiClient: apiClient)
                )
                profileRequiresAuthentication = !hasStaticAuthToken
            } else {
                profileRepository = localProfileRepository
                profileRequiresAuthentication = false
            }
        } else {
            authRepository = LocalAuthRepository()
            projectRepository = LocalProjectRepository()
            patternRepository = LocalPatternRepository()
            gaugeRecordRepository = LocalGaugeRecordRepository()
            gaugeTargetRepository = LocalGaugeTargetRepository()
            progressPhotoRepository = LocalProjectProgressPhotoRepository()
            libraryRepository = LocalLibraryRepository()
            skillRepository = LocalSkillRepository()
            dictionaryRepository = LocalDictionaryRepository()
            profileRepository = LocalProfileRepository()
            profileRequiresAuthentication = false
        }

        return AppRepositoryContainer(
            authRepository: authRepository,
            authSessionStore: authSessionStore,
            projectRepository: projectRepository,
            patternRepository: patternRepository,
            gaugeRecordRepository: gaugeRecordRepository,
            gaugeTargetRepository: gaugeTargetRepository,
            progressPhotoRepository: progressPhotoRepository,
            libraryRepository: libraryRepository,
            skillRepository: skillRepository,
            dictionaryRepository: dictionaryRepository,
            profileRepository: profileRepository,
            profileRequiresAuthentication: profileRequiresAuthentication
        )
    }

    private static func apiBaseURL(from environment: [String: String]) -> URL? {
        let envValue = environment["KNITGETHER_API_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let candidate: String?
        if let envValue, !envValue.isEmpty {
            candidate = envValue
        } else {
            candidate = standaloneDeviceAPIBaseURL()
        }

        guard
            let value = candidate,
            !value.isEmpty,
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return nil
        }

        return url
    }

    /// Scheme environment variables are only injected when Xcode launches the app.
    /// A physical device is normally opened by tapping the app icon, which carries
    /// no scheme env, so fall back to the local dev server there. The simulator keeps
    /// its env-only behavior so UI tests and the Local Simulator/Offline schemes are
    /// unaffected.
    private static func standaloneDeviceAPIBaseURL() -> String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return "http://haeun.local:3000/api/v1"
        #endif
    }

    private static func apiAuthToken(from environment: [String: String]) -> String? {
        let token = environment["KNITGETHER_API_AUTH_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return token?.isEmpty == false ? token : nil
    }

    private static func devAuthToken(from environment: [String: String]) -> String? {
        if environment["KNITGETHER_DISABLE_DEV_AUTH_TOKEN"] == "1" {
            return nil
        }

        let token = environment["KNITGETHER_DEV_AUTH_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return token?.isEmpty == false ? token : nil
    }

    private static func remoteCacheDirectoryURL(
        from environment: [String: String],
        baseURL: URL,
        userId: String?,
        fileManager: FileManager = .default
    ) -> URL {
        if let value = environment["KNITGETHER_LOCAL_CACHE_DIRECTORY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return URL(fileURLWithPath: value, isDirectory: true)
        }

        let cacheRootDirectoryURL: URL
        if let value = environment["KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            cacheRootDirectoryURL = URL(fileURLWithPath: value, isDirectory: true)
        } else {
            let baseDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            cacheRootDirectoryURL = baseDirectoryURL
                .appendingPathComponent("KnitGether", isDirectory: true)
                .appendingPathComponent("RemoteCaches", isDirectory: true)
        }

        return cacheRootDirectoryURL
            .appendingPathComponent(cacheScopeName(for: baseURL), isDirectory: true)
            .appendingPathComponent(cacheUserScopeName(for: userId), isDirectory: true)
    }

    private static func cacheFileURL(_ fileName: String, in directoryURL: URL) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    private static func cacheScopeName(for baseURL: URL) -> String {
        let rawValue = [
            baseURL.scheme,
            baseURL.host,
            baseURL.port.map(String.init),
            baseURL.path
        ]
            .compactMap { $0 }
            .joined(separator: "-")

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = rawValue.unicodeScalars
            .map { allowedCharacters.contains($0) ? String($0) : "-" }
            .joined()

        return sanitized.isEmpty ? "default" : sanitized
    }

    private static func cacheUserScopeName(for userId: String?) -> String {
        let trimmedUserId = userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawValue = trimmedUserId.isEmpty ? "anonymous" : trimmedUserId
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = rawValue.unicodeScalars
            .map { allowedCharacters.contains($0) ? String($0) : "-" }
            .joined()

        return sanitized.isEmpty ? "anonymous" : sanitized
    }
}

@MainActor
final class AppRepositoryStore: ObservableObject {
    @Published private(set) var container: AppRepositoryContainer

    private let environment: [String: String]
    private let session: URLSession
    private let authSessionStore: AuthSessionStore
    private var currentSessionScope: String
    private var sessionCancellable: AnyCancellable?

    convenience init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        session: URLSession = .shared
    ) {
        self.init(
            environment: environment,
            session: session,
            authSessionStore: .shared
        )
    }

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        session: URLSession = .shared,
        authSessionStore: AuthSessionStore
    ) {
        self.environment = environment
        self.session = session
        self.authSessionStore = authSessionStore
        self.currentSessionScope = Self.sessionScope(for: authSessionStore.currentSession)
        self.container = AppRepositoryContainer.makeDefault(
            environment: environment,
            session: session,
            authSessionStore: authSessionStore
        )

        sessionCancellable = authSessionStore.$currentSession
            .dropFirst()
            .sink { [weak self] session in
                Task { @MainActor in
                    self?.rebuildIfSessionScopeChanged(session)
                }
            }
    }

    private func rebuildIfSessionScopeChanged(_ session: AuthSession?) {
        let nextSessionScope = Self.sessionScope(for: session)
        guard nextSessionScope != currentSessionScope else {
            return
        }

        currentSessionScope = nextSessionScope
        container = AppRepositoryContainer.makeDefault(
            environment: environment,
            session: self.session,
            authSessionStore: authSessionStore
        )
    }

    private static func sessionScope(for session: AuthSession?) -> String {
        let userId = session?.profile.ownerId ?? session?.profile.id
        let trimmedUserId = userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedUserId.isEmpty ? "anonymous" : trimmedUserId
    }
}
