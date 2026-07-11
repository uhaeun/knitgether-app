import Foundation

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let profile: UserProfile
}

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String
    let profile: UserProfile
}
