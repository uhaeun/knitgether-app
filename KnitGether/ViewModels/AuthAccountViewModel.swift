import Combine
import Foundation

struct AuthAccountFormData {
    var email = ""
    var password = ""
    var displayName = ""
    var preferredUnits = "Metric"

    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canLogin: Bool {
        trimmedEmail.contains("@") && password.count >= 8
    }

    var canRegister: Bool {
        canLogin && !trimmedDisplayName.isEmpty
    }
}

@MainActor
final class AuthAccountViewModel: ObservableObject {
    @Published private(set) var currentSession: AuthSession?
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefreshingAccount = false
    @Published var formData = AuthAccountFormData()

    private let authRepository: any AuthRepository
    private let sessionStore: AuthSessionStore

    init(
        authRepository: any AuthRepository,
        sessionStore: AuthSessionStore
    ) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        currentSession = sessionStore.currentSession
    }

    var hasAccountRefreshError: Bool {
        currentSession != nil && currentUser == nil && errorMessage != nil
    }

    func loadSession() async {
        currentSession = sessionStore.currentSession

        guard currentSession != nil else {
            currentUser = nil
            errorMessage = nil
            return
        }

        do {
            currentUser = try await authRepository.fetchCurrentUser()
            errorMessage = nil
        } catch {
            currentUser = nil
            errorMessage = "계정 정보를 새로고침하지 못했어요."
        }
    }

    func retryLoadSession() async {
        guard !isRefreshingAccount else {
            return
        }

        isRefreshingAccount = true
        await loadSession()
        isRefreshingAccount = false
    }

    func login() async -> Bool {
        guard formData.canLogin else {
            errorMessage = "이메일과 비밀번호를 확인해 주세요."
            return false
        }

        do {
            let session = try await authRepository.login(
                email: formData.trimmedEmail,
                password: formData.password
            )
            try sessionStore.save(session)
            currentSession = session
            await refreshCurrentUserAfterAuthentication()
            return true
        } catch {
            errorMessage = "로그인하지 못했어요."
            return false
        }
    }

    func register() async -> Bool {
        guard formData.canRegister else {
            errorMessage = "이메일, 비밀번호, 이름을 확인해 주세요."
            return false
        }

        do {
            let session = try await authRepository.register(
                email: formData.trimmedEmail,
                password: formData.password,
                displayName: formData.trimmedDisplayName,
                preferredUnits: formData.preferredUnits
            )
            try sessionStore.save(session)
            currentSession = session
            await refreshCurrentUserAfterAuthentication()
            return true
        } catch {
            errorMessage = "회원가입하지 못했어요."
            return false
        }
    }

    func signOut() throws {
        try sessionStore.clear()
        currentSession = nil
        currentUser = nil
        errorMessage = nil
        formData.password = ""
    }

    private func refreshCurrentUserAfterAuthentication() async {
        do {
            currentUser = try await authRepository.fetchCurrentUser()
            errorMessage = nil
        } catch {
            currentUser = nil
            errorMessage = "계정 정보를 새로고침하지 못했어요."
        }
    }
}
