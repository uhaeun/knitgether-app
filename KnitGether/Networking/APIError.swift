import Foundation

nonisolated struct APIErrorEnvelope: Decodable {
    let code: String?
    let message: String?
}

nonisolated enum APIError: Error, Equatable {
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String?)
    case decodingFailed(message: String)
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

    /// 프로젝트 낙관적 잠금 충돌(다른 기기에서 먼저 수정됨).
    /// 서버는 baseUpdatedAt이 서버 updatedAt보다 오래된 저장 요청에
    /// 409와 code PROJECT_CONFLICT를 돌려준다.
    var isProjectConflict: Bool {
        statusCode == 409 && code == "PROJECT_CONFLICT"
    }
}
