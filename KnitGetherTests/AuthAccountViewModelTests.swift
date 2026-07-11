import Foundation
import Testing
@testable import KnitGether

@MainActor
struct AuthAccountViewModelTests {
    @Test func loginSavesSessionAndLoadsCurrentUser() async throws {
        let repository = FakeAuthRepository()
        let store = AuthSessionStore(
            userDefaults: Self.makeDefaults(),
            tokenStorage: InMemoryAuthTokenStorage()
        )
        let viewModel = AuthAccountViewModel(
            authRepository: repository,
            sessionStore: store
        )
        viewModel.formData.email = "yuha@example.com"
        viewModel.formData.password = "password-1234"

        let didLogin = await viewModel.login()

        #expect(didLogin)
        #expect(store.currentSession?.accessToken == "jwt-token")
        #expect(viewModel.currentUser?.email == "yuha@example.com")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func registerSavesSession() async throws {
        let repository = FakeAuthRepository()
        let store = AuthSessionStore(
            userDefaults: Self.makeDefaults(),
            tokenStorage: InMemoryAuthTokenStorage()
        )
        let viewModel = AuthAccountViewModel(
            authRepository: repository,
            sessionStore: store
        )
        viewModel.formData.email = "yuha@example.com"
        viewModel.formData.password = "password-1234"
        viewModel.formData.displayName = "Yuha"
        viewModel.formData.preferredUnits = "Metric"

        let didRegister = await viewModel.register()

        #expect(didRegister)
        #expect(repository.registerRequests.count == 1)
        #expect(store.currentSession?.profile.displayName == "Yuha")
    }

    @Test func signOutClearsStoredSession() async throws {
        let store = AuthSessionStore(
            userDefaults: Self.makeDefaults(),
            tokenStorage: InMemoryAuthTokenStorage()
        )
        try store.save(Self.makeSession())
        let viewModel = AuthAccountViewModel(
            authRepository: FakeAuthRepository(),
            sessionStore: store
        )

        await viewModel.loadSession()
        try viewModel.signOut()

        #expect(store.currentSession == nil)
        #expect(viewModel.currentSession == nil)
    }

    @Test func loadSessionShowsRefreshErrorWhenCurrentUserCannotLoad() async throws {
        let repository = FakeAuthRepository()
        repository.fetchCurrentUserResults = [.failure(AuthRepositoryError.serverUnavailable)]
        let store = AuthSessionStore(
            userDefaults: Self.makeDefaults(),
            tokenStorage: InMemoryAuthTokenStorage()
        )
        try store.save(Self.makeSession())
        let viewModel = AuthAccountViewModel(
            authRepository: repository,
            sessionStore: store
        )

        await viewModel.loadSession()

        #expect(viewModel.currentSession?.accessToken == "jwt-token")
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.hasAccountRefreshError)
        #expect(viewModel.errorMessage == "계정 정보를 새로고침하지 못했어요.")
    }

    @Test func retryLoadSessionReloadsCurrentUserAndClearsRefreshError() async throws {
        let repository = FakeAuthRepository()
        repository.fetchCurrentUserResults = [
            .failure(AuthRepositoryError.serverUnavailable),
            .success(Self.makeCurrentUser())
        ]
        let store = AuthSessionStore(
            userDefaults: Self.makeDefaults(),
            tokenStorage: InMemoryAuthTokenStorage()
        )
        try store.save(Self.makeSession())
        let viewModel = AuthAccountViewModel(
            authRepository: repository,
            sessionStore: store
        )

        await viewModel.loadSession()
        await viewModel.retryLoadSession()

        #expect(repository.fetchCurrentUserCallCount == 2)
        #expect(viewModel.currentUser?.email == "yuha@example.com")
        #expect(!viewModel.hasAccountRefreshError)
        #expect(!viewModel.isRefreshingAccount)
        #expect(viewModel.errorMessage == nil)
    }

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "AuthAccountViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func makeSession() -> AuthSession {
        let now = Date(timeIntervalSince1970: 1_783_735_200)
        return AuthSession(
            accessToken: "jwt-token",
            tokenType: "Bearer",
            profile: UserProfile(
                id: "user-a",
                ownerId: "user-a",
                displayName: "Yuha",
                preferredUnits: "Metric",
                createdAt: now,
                updatedAt: now,
                deletedAt: nil,
                syncStatus: .synced
            )
        )
    }

    static func makeCurrentUser() -> AuthUser {
        AuthUser(
            id: "user-a",
            email: "yuha@example.com",
            profile: makeSession().profile
        )
    }
}

@MainActor
private final class FakeAuthRepository: AuthRepository {
    var registerRequests: [(email: String, password: String, displayName: String, preferredUnits: String)] = []
    var fetchCurrentUserResults: [Result<AuthUser, Error>] = []
    var fetchCurrentUserCallCount = 0

    func register(
        email: String,
        password: String,
        displayName: String,
        preferredUnits: String
    ) async throws -> AuthSession {
        registerRequests.append((email, password, displayName, preferredUnits))
        return AuthAccountViewModelTests.makeSession()
    }

    func login(email: String, password: String) async throws -> AuthSession {
        AuthAccountViewModelTests.makeSession()
    }

    func fetchCurrentUser() async throws -> AuthUser {
        fetchCurrentUserCallCount += 1

        if !fetchCurrentUserResults.isEmpty {
            switch fetchCurrentUserResults.removeFirst() {
            case let .success(user):
                return user
            case let .failure(error):
                throw error
            }
        }

        return AuthAccountViewModelTests.makeCurrentUser()
    }
}
