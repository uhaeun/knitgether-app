import Foundation

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let contentType: String
    let data: Data
}

nonisolated final class APIClient {
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

            if let date = Self.date(fromISO8601String: value, includesFractionalSeconds: true) {
                return date
            }

            if let date = Self.date(fromISO8601String: value, includesFractionalSeconds: false) {
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

    func uploadMultipart<Response: Decodable>(
        _ path: String,
        fields: [String: String],
        file: MultipartFile
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = multipartBody(boundary: boundary, fields: fields, file: file)
        return try await request(
            path,
            method: "POST",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    func downloadData(_ path: String) async throws -> Data {
        try await requestData(
            path,
            method: "GET",
            body: Optional<Data>.none,
            contentType: nil
        )
    }

    private func request<Response: Decodable>(
        _ path: String,
        method: String,
        body: Data?,
        contentType: String? = "application/json"
    ) async throws -> Response {
        let data = try await requestData(
            path,
            method: method,
            body: body,
            contentType: contentType
        )

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
        _ = try await requestData(
            path,
            method: method,
            body: body,
            contentType: "application/json"
        )
    }

    private func requestData(
        _ path: String,
        method: String,
        body: Data?,
        contentType: String?
    ) async throws -> Data {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            if let contentType {
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }

        if let token = try await configuration.authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        Self.debugLog("REQUEST \(method) \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Self.debugLog("ERROR \(method) \(url.absoluteString) \(error)")
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            Self.debugLog("ERROR \(method) \(url.absoluteString) invalid response")
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                await configuration.authFailureHandler()
            }

            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            Self.debugLog(
                "RESPONSE \(method) \(url.absoluteString) status=\(httpResponse.statusCode) code=\(envelope?.code ?? "-") message=\(envelope?.message ?? "-")"
            )
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                code: envelope?.code,
                message: envelope?.message
            )
        }

        Self.debugLog("RESPONSE \(method) \(url.absoluteString) status=\(httpResponse.statusCode)")
        return data
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[KnitGether API] \(message)")
        #endif
    }

    private func multipartBody(
        boundary: String,
        fields: [String: String],
        file: MultipartFile
    ) -> Data {
        var data = Data()
        let lineBreak = "\r\n"

        for key in fields.keys.sorted() {
            guard let value = fields[key] else {
                continue
            }
            data.appendString("--\(boundary)\(lineBreak)")
            data.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            data.appendString("\(value)\(lineBreak)")
        }

        data.appendString("--\(boundary)\(lineBreak)")
        data.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(lineBreak)")
        data.appendString("Content-Type: \(file.contentType)\(lineBreak)\(lineBreak)")
        data.append(file.data)
        data.appendString(lineBreak)
        data.appendString("--\(boundary)--\(lineBreak)")

        return data
    }

    private static func date(
        fromISO8601String value: String,
        includesFractionalSeconds: Bool
    ) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = includesFractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

nonisolated private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
