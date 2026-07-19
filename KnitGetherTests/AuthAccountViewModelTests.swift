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
        #expect(viewModel.statusMessage == "로그인했어요.")
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
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.statusMessage == "회원가입이 완료됐어요.")
    }

    @Test func registerShowsDuplicateEmailMessage() async throws {
        let repository = FakeAuthRepository()
        repository.registerResults = [
            .failure(APIError.requestFailed(
                statusCode: 409,
                code: "EMAIL_ALREADY_REGISTERED",
                message: "Email is already registered."
            ))
        ]
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

        let didRegister = await viewModel.register()

        #expect(!didRegister)
        #expect(viewModel.errorMessage == "이미 가입된 이메일이에요. 로그인하거나 다른 이메일을 사용해 주세요.")
        #expect(viewModel.statusMessage == nil)
    }

    @Test func registerShowsConnectionMessageForNetworkFailure() async throws {
        let repository = FakeAuthRepository()
        repository.registerResults = [
            .failure(URLError(.cannotConnectToHost))
        ]
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

        let didRegister = await viewModel.register()

        #expect(!didRegister)
        #expect(viewModel.errorMessage == "서버에 연결하지 못했어요. 같은 Wi-Fi와 Local Device 설정을 확인해 주세요.")
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
        #expect(viewModel.statusMessage == "로그아웃했어요.")
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
    var registerResults: [Result<AuthSession, Error>] = []
    var loginResults: [Result<AuthSession, Error>] = []
    var fetchCurrentUserResults: [Result<AuthUser, Error>] = []
    var fetchCurrentUserCallCount = 0

    func register(
        email: String,
        password: String,
        displayName: String,
        preferredUnits: String
    ) async throws -> AuthSession {
        registerRequests.append((email, password, displayName, preferredUnits))

        if !registerResults.isEmpty {
            switch registerResults.removeFirst() {
            case let .success(session):
                return session
            case let .failure(error):
                throw error
            }
        }

        return AuthAccountViewModelTests.makeSession()
    }

    func login(email: String, password: String) async throws -> AuthSession {
        if !loginResults.isEmpty {
            switch loginResults.removeFirst() {
            case let .success(session):
                return session
            case let .failure(error):
                throw error
            }
        }

        return AuthAccountViewModelTests.makeSession()
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
