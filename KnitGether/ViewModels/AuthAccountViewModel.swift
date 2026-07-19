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
    @Published private(set) var statusMessage: String?
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
            statusMessage = nil
            return
        }

        do {
            currentUser = try await authRepository.fetchCurrentUser()
            errorMessage = nil
        } catch {
            currentUser = nil
            errorMessage = "계정 정보를 새로고침하지 못했어요."
            statusMessage = nil
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
            statusMessage = nil
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
            if errorMessage == nil {
                statusMessage = "로그인했어요."
            }
            return true
        } catch {
            errorMessage = Self.authenticationErrorMessage(
                for: error,
                fallback: "로그인하지 못했어요."
            )
            statusMessage = nil
            Self.debugLog("login failed: \(error)")
            return false
        }
    }

    func register() async -> Bool {
        guard formData.canRegister else {
            errorMessage = "이메일, 비밀번호, 이름을 확인해 주세요."
            statusMessage = nil
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
            if errorMessage == nil {
                statusMessage = "회원가입이 완료됐어요."
            }
            return true
        } catch {
            errorMessage = Self.authenticationErrorMessage(
                for: error,
                fallback: "회원가입하지 못했어요."
            )
            statusMessage = nil
            Self.debugLog("register failed: \(error)")
            return false
        }
    }

    func signOut() throws {
        try sessionStore.clear()
        currentSession = nil
        currentUser = nil
        errorMessage = nil
        statusMessage = "로그아웃했어요."
        formData.password = ""
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    private func refreshCurrentUserAfterAuthentication() async {
        do {
            currentUser = try await authRepository.fetchCurrentUser()
            errorMessage = nil
        } catch {
            currentUser = nil
            errorMessage = Self.authenticationErrorMessage(
                for: error,
                fallback: "계정 정보를 새로고침하지 못했어요."
            )
            statusMessage = nil
            Self.debugLog("fetch current user after authentication failed: \(error)")
        }
    }

    private static func authenticationErrorMessage(
        for error: Error,
        fallback: String
    ) -> String {
        if error is URLError {
            return "서버에 연결하지 못했어요. 같은 Wi-Fi와 Local Device 설정을 확인해 주세요."
        }

        if let authError = error as? AuthRepositoryError {
            switch authError {
            case .serverUnavailable:
                return "서버 API 설정이 없어요. Xcode에서 KnitGether Local Device로 실행해 주세요."
            }
        }

        if let apiError = error as? APIError {
            switch apiError.code {
            case "EMAIL_ALREADY_REGISTERED":
                return "이미 가입된 이메일이에요. 로그인하거나 다른 이메일을 사용해 주세요."
            case "INVALID_CREDENTIALS":
                return "이메일 또는 비밀번호가 맞지 않아요."
            case "UNAUTHENTICATED":
                return "로그인 정보가 만료됐어요. 다시 로그인해 주세요."
            default:
                break
            }

            switch apiError.statusCode {
            case 400:
                return "입력값을 확인해 주세요."
            case 401:
                return "로그인 정보가 만료됐어요. 다시 로그인해 주세요."
            case 409:
                return "이미 가입된 정보가 있어요."
            case let statusCode? where statusCode >= 500:
                return "서버에서 문제가 발생했어요. 서버 Terminal 로그를 확인해 주세요."
            case let statusCode?:
                return "서버 요청이 실패했어요. 상태 코드 \(statusCode)."
            case nil:
                if case .decodingFailed = apiError {
                    return "서버 응답을 앱이 읽지 못했어요. Xcode 콘솔을 확인해 주세요."
                }
            }
        }

        return fallback
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[KnitGether Auth] \(message)")
        #endif
    }
}
