import Foundation

protocol AuthRepository {
    func register(
        email: String,
        password: String,
        displayName: String,
        preferredUnits: String
    ) async throws -> AuthSession

    func login(email: String, password: String) async throws -> AuthSession
    func fetchCurrentUser() async throws -> AuthUser
}

enum AuthRepositoryError: LocalizedError {
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .serverUnavailable:
            return "서버 API 설정이 필요합니다."
        }
    }
}
