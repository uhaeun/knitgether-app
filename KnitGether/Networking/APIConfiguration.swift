import Foundation

nonisolated struct APIConfiguration {
    let baseURL: URL
    let authTokenProvider: @Sendable () async throws -> String?
    let authFailureHandler: @Sendable () async -> Void

    init(
        baseURL: URL,
        authTokenProvider: @escaping @Sendable () async throws -> String? = { nil },
        authFailureHandler: @escaping @Sendable () async -> Void = {}
    ) {
        self.baseURL = baseURL
        self.authTokenProvider = authTokenProvider
        self.authFailureHandler = authFailureHandler
    }
}
