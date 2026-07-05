import Foundation

struct APIConfiguration {
    let baseURL: URL
    let authTokenProvider: @Sendable () async throws -> String?
}
