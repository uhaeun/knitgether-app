import Foundation

final class RemoteAuthRepository: AuthRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func register(
        email: String,
        password: String,
        displayName: String,
        preferredUnits: String
    ) async throws -> AuthSession {
        try await apiClient.send(
            "auth/register",
            method: "POST",
            body: RegisterRequest(
                email: email,
                password: password,
                displayName: displayName,
                preferredUnits: preferredUnits
            )
        )
    }

    func login(email: String, password: String) async throws -> AuthSession {
        try await apiClient.send(
            "auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password)
        )
    }

    func fetchCurrentUser() async throws -> AuthUser {
        try await apiClient.get("auth/me")
    }
}

private struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let displayName: String
    let preferredUnits: String
}

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}
