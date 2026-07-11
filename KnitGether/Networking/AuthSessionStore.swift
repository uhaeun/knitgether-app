import Combine
import Foundation
import Security

protocol AuthTokenStorage {
    nonisolated func loadToken() throws -> String?
    nonisolated func saveToken(_ token: String) throws
    nonisolated func clearToken() throws
}

enum AuthSessionStoreError: Error {
    case keychain(status: OSStatus)
    case invalidTokenData
}

struct KeychainAuthTokenStorage: AuthTokenStorage {
    private let service: String
    private let account: String

    nonisolated init(
        service: String = "com.uhaeun.KnitGether.auth",
        account: String = "access-token"
    ) {
        self.service = service
        self.account = account
    }

    nonisolated func loadToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw AuthSessionStoreError.keychain(status: status)
        }

        guard
            let data = item as? Data,
            let token = String(data: data, encoding: .utf8)
        else {
            throw AuthSessionStoreError.invalidTokenData
        }

        return token
    }

    nonisolated func saveToken(_ token: String) throws {
        try clearToken()

        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw AuthSessionStoreError.keychain(status: status)
        }
    }

    nonisolated func clearToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthSessionStoreError.keychain(status: status)
        }
    }

    private nonisolated var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

@MainActor
final class AuthSessionStore: ObservableObject {
    static let shared = AuthSessionStore()

    @Published private(set) var currentSession: AuthSession?

    private let userDefaults: UserDefaults
    private let tokenStorage: AuthTokenStorage
    private let profileKey: String

    init(
        userDefaults: UserDefaults = .standard,
        tokenStorage: AuthTokenStorage = KeychainAuthTokenStorage(),
        profileKey: String = "KnitGether.auth.profile"
    ) {
        self.userDefaults = userDefaults
        self.tokenStorage = tokenStorage
        self.profileKey = profileKey
        currentSession = Self.restoreSession(
            userDefaults: userDefaults,
            tokenStorage: tokenStorage,
            profileKey: profileKey
        )
    }

    func accessToken() -> String? {
        try? tokenStorage.loadToken()
    }

    func save(_ session: AuthSession) throws {
        try tokenStorage.saveToken(session.accessToken)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        userDefaults.set(try encoder.encode(session.profile), forKey: profileKey)
        currentSession = session
    }

    func clear() throws {
        try tokenStorage.clearToken()
        userDefaults.removeObject(forKey: profileKey)
        currentSession = nil
    }

    private static func restoreSession(
        userDefaults: UserDefaults,
        tokenStorage: AuthTokenStorage,
        profileKey: String
    ) -> AuthSession? {
        guard
            let token = try? tokenStorage.loadToken(),
            let data = userDefaults.data(forKey: profileKey)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let profile = try? decoder.decode(UserProfile.self, from: data) else {
            return nil
        }

        return AuthSession(
            accessToken: token,
            tokenType: "Bearer",
            profile: profile
        )
    }
}
