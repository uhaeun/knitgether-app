import Foundation
import Testing
@testable import KnitGether

struct RemoteGaugeRecordRepositoryTests {
    @Test func fetchGaugeRecordsLoadsServerRecords() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-records")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.gaugeRecordsJSON.utf8))
        }

        let repository = RemoteGaugeRecordRepository(apiClient: Self.apiClient(session: session))
        let records = try await repository.fetchGaugeRecords()

        #expect(records.count == 1)
        #expect(records[0].measurementStage == .beforeWash)
        #expect(records[0].projectNameSnapshot == "Favorite Cardigan")
        #expect(records[0].targetRows == 165)
    }

    @Test func saveGaugeRecordPostsRecordToServer() async throws {
        let record = Self.makeGaugeRecord()
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-records")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#""measurementStage":"beforeWash""#))
            #expect(bodyString.contains(#""projectNameSnapshot":"Favorite Cardigan""#))
            #expect(bodyString.contains(#""sampleWidthCm":10"#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.gaugeRecordsJSON.dropFirst().dropLast().utf8))
        }

        let repository = RemoteGaugeRecordRepository(apiClient: Self.apiClient(session: session))
        let saved = try await repository.saveGaugeRecord(record)

        #expect(saved.id == record.id)
        #expect(saved.syncStatus == .synced)
    }

    @Test func updateGaugeRecordPatchesExistingRecordOnServer() async throws {
        let record = Self.makeGaugeRecord()
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-records/88888888-8888-4888-8888-888888888888")
            #expect(request.httpMethod == "PATCH")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#""measurementStage":"beforeWash""#))
            #expect(bodyString.contains(#""needle":"4.0mm circular""#))
            #expect(bodyString.contains(#""memo":"Measured before blocking.""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.gaugeRecordsJSON.dropFirst().dropLast().utf8))
        }

        let repository = RemoteGaugeRecordRepository(apiClient: Self.apiClient(session: session))
        let saved = try await repository.updateGaugeRecord(record)

        #expect(saved.id == record.id)
        #expect(saved.syncStatus == .synced)
    }

    private static func apiClient(session: URLSession) -> APIClient {
        APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )
    }

    private static func makeGaugeRecord() -> GaugeRecord {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return GaugeRecord(
            id: UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            projectNameSnapshot: "Favorite Cardigan",
            patternNameSnapshot: "Cozy Shawl",
            measurementStage: .beforeWash,
            sampleWidthCm: 10,
            sampleHeightCm: 10,
            stitchCount: 22,
            rowCount: 30,
            targetWidthCm: 40,
            targetHeightCm: 55,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            targetStitches: 88,
            targetRows: 165,
            needle: "4.0mm circular",
            memo: "Measured before blocking.",
            measuredAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
    }

    private static func bodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let bodyStream = request.httpBodyStream else {
            Issue.record("Expected request body")
            return Data()
        }

        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        let bufferSize = 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while bodyStream.hasBytesAvailable {
            let readCount = bodyStream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if readCount == 0 {
                break
            }
            data.append(buffer, count: readCount)
        }

        return data
    }

    private static let gaugeRecordsJSON = """
    [{
      "id":"88888888-8888-4888-8888-888888888888",
      "ownerId":"user-a",
      "projectId":"11111111-1111-4111-8111-111111111111",
      "projectNameSnapshot":"Favorite Cardigan",
      "patternNameSnapshot":"Cozy Shawl",
      "measurementStage":"beforeWash",
      "sampleWidthCm":10,
      "sampleHeightCm":10,
      "stitchCount":22,
      "rowCount":30,
      "targetWidthCm":40,
      "targetHeightCm":55,
      "stitchesPer10Cm":22,
      "rowsPer10Cm":30,
      "targetStitches":88,
      "targetRows":165,
      "needle":"4.0mm circular",
      "memo":"Measured before blocking.",
      "measuredAt":"2026-07-08T12:00:00.000Z",
      "createdAt":"2026-07-08T12:01:00.000Z",
      "updatedAt":"2026-07-08T12:01:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced"
    }]
    """
}
