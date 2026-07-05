import Foundation

final class APIClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        configuration: APIConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = Self.fractionalISO8601Formatter.date(from: value) {
                return date
            }

            if let date = Self.iso8601Formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await request(path, method: "GET", body: Optional<Data>.none)
    }

    func send<RequestBody: Encodable, Response: Decodable>(
        _ path: String,
        method: String,
        body: RequestBody
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await request(path, method: method, body: data)
    }

    func delete(_ path: String) async throws {
        try await requestWithoutResponse(path, method: "DELETE", body: Optional<Data>.none)
    }

    private func request<Response: Decodable>(
        _ path: String,
        method: String,
        body: Data?
    ) async throws -> Response {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = try await configuration.authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                code: envelope?.code,
                message: envelope?.message
            )
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed(message: String(describing: error))
        }
    }

    private func requestWithoutResponse(
        _ path: String,
        method: String,
        body: Data?
    ) async throws {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = try await configuration.authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                code: envelope?.code,
                message: envelope?.message
            )
        }
    }

    private static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
