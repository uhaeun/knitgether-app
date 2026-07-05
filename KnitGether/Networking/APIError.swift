import Foundation

struct APIErrorEnvelope: Decodable {
    let code: String?
    let message: String?
}

enum APIError: Error, Equatable {
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String?)
    case decodingFailed
    case unsupportedOperation(String)

    var statusCode: Int? {
        if case let .requestFailed(statusCode, _, _) = self {
            return statusCode
        }
        return nil
    }

    var code: String? {
        if case let .requestFailed(_, code, _) = self {
            return code
        }
        return nil
    }

    var message: String? {
        if case let .requestFailed(_, _, message) = self {
            return message
        }
        return nil
    }
}
