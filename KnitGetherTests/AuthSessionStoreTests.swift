import Foundation
import Testing
@testable import KnitGether

@MainActor
struct AuthSessionStoreTests {
    @Test func saveRestoreAndClearSession() async throws {
        let suiteName = "AuthSessionStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let tokenStorage = InMemoryAuthTokenStorage()
        let session = Self.makeSession()

        let store = AuthSessionStore(
            userDefaults: defaults,
            tokenStorage: tokenStorage
        )
        try store.save(session)

        #expect(store.currentSession?.accessToken == "jwt-token")
        #expect(store.accessToken() == "jwt-token")

        let restored = AuthSessionStore(
            userDefaults: defaults,
            tokenStorage: tokenStorage
        )

        #expect(restored.currentSession?.accessToken == "jwt-token")
        #expect(restored.currentSession?.profile.id == "user-a")

        try restored.clear()

        #expect(restored.currentSession == nil)
        #expect(restored.accessToken() == nil)
    }

    private static func makeSession() -> AuthSession {
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
}

final class InMemoryAuthTokenStorage: AuthTokenStorage {
    var token: String?

    func loadToken() throws -> String? {
        token
    }

    func saveToken(_ token: String) throws {
        self.token = token
    }

    func clearToken() throws {
        token = nil
    }
}
