import Foundation

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let contentType: String
    let data: Data
}

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

        return data
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

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
