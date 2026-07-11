import Foundation
import Testing
@testable import KnitGether

@MainActor
struct RemoteGaugeTargetRepositoryTests {
    @Test func fetchGaugeTargetsLoadsNestedSwatchesAndMeasurements() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-targets")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.gaugeTargetsJSON.utf8))
        }

        let repository = RemoteGaugeTargetRepository(apiClient: Self.apiClient(session: session))
        let targets = try await repository.fetchGaugeTargets()

        #expect(targets.count == 1)
        #expect(targets[0].name == "Cozy Shawl gauge")
        #expect(targets[0].swatches.count == 1)
        #expect(targets[0].swatches[0].measurements.count == 1)
        #expect(targets[0].swatches[0].measurements[0].washState == .before)
        #expect(targets[0].swatches[0].measurements[0].finalRows == 30)
    }

    @Test func saveGaugeTargetPostsNestedMeasurementData() async throws {
        let target = Self.makeGaugeTarget()
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-targets")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let body = try Self.bodyData(from: request)
            let bodyString = String(decoding: body, as: UTF8.self)
            #expect(bodyString.contains(#""name":"Cozy Shawl gauge""#))
            #expect(bodyString.contains(#""washState":"before""#))
            #expect(bodyString.contains(#""yarnName":"Soft Merino DK""#))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.gaugeTargetsJSON.dropFirst().dropLast().utf8))
        }

        let repository = RemoteGaugeTargetRepository(apiClient: Self.apiClient(session: session))
        let saved = try await repository.saveGaugeTarget(target)

        #expect(saved.id == target.id)
        #expect(saved.syncStatus == .synced)
        #expect(saved.swatches[0].measurements[0].method == .manual)
    }

    @Test func deleteGaugeTargetDeletesServerTarget() async throws {
        let targetId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/gauge-targets/\(targetId.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = RemoteGaugeTargetRepository(apiClient: Self.apiClient(session: session))
        try await repository.deleteGaugeTarget(id: targetId)
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

    private static func makeGaugeTarget() -> GaugeTarget {
        let targetId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let swatchId = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let measurement = GaugeMeasurement(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
            ownerId: "user-a",
            gaugeTargetId: targetId,
            gaugeSwatchId: swatchId,
            method: .manual,
            washState: .before,
            measuredWidth: 10,
            measuredHeight: 10,
            rawStitches: 22,
            rawRows: 30,
            normalizedStitches: 22,
            normalizedRows: 30,
            finalStitches: 22,
            finalRows: 30,
            autoStitches: 0,
            autoRows: 0,
            autoConfidence: nil,
            userModified: false,
            photoPath: nil,
            cornerCoordinates: nil,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )

        let swatch = GaugeSwatch(
            id: swatchId,
            ownerId: "user-a",
            gaugeTargetId: targetId,
            isSelected: true,
            knittedAt: now,
            needleMaterial: "Wood",
            needleSize: "4.0 mm",
            needleType: "Circular",
            notes: "Before blocking.",
            stitchPattern: "stockinette",
            yarnBrand: "Sample Yarn Co.",
            yarnColor: "Cloud Gray",
            yarnLot: "LOT-1",
            yarnName: "Soft Merino DK",
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly,
            measurements: [measurement]
        )

        return GaugeTarget(
            id: targetId,
            ownerId: "user-a",
            name: "Cozy Shawl gauge",
            targetStitches: 22,
            targetWidth: 10,
            targetRows: 30,
            targetHeight: 10,
            isQuickMeasure: false,
            gaugeAfterWash: true,
            recommendedNeedle: "4.0 mm circular",
            sourcePatternId: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"),
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly,
            swatches: [swatch]
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

    private static let gaugeTargetsJSON = """
    [{
      "id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "ownerId":"user-a",
      "name":"Cozy Shawl gauge",
      "targetStitches":22,
      "targetWidth":10,
      "targetRows":30,
      "targetHeight":10,
      "isQuickMeasure":false,
      "gaugeAfterWash":true,
      "recommendedNeedle":"4.0 mm circular",
      "sourcePatternId":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      "createdAt":"2026-07-09T03:00:00.000Z",
      "updatedAt":"2026-07-09T03:00:00.000Z",
      "deletedAt":null,
      "syncStatus":"Synced",
      "swatches":[{
        "id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        "ownerId":"user-a",
        "gaugeTargetId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        "isSelected":true,
        "knittedAt":"2026-07-09T02:00:00.000Z",
        "needleMaterial":"Wood",
        "needleSize":"4.0 mm",
        "needleType":"Circular",
        "notes":"Before blocking.",
        "stitchPattern":"stockinette",
        "yarnBrand":"Sample Yarn Co.",
        "yarnColor":"Cloud Gray",
        "yarnLot":"LOT-1",
        "yarnName":"Soft Merino DK",
        "createdAt":"2026-07-09T03:01:00.000Z",
        "updatedAt":"2026-07-09T03:01:00.000Z",
        "deletedAt":null,
        "syncStatus":"Synced",
        "measurements":[{
          "id":"dddddddd-dddd-4ddd-8ddd-dddddddddddd",
          "ownerId":"user-a",
          "gaugeTargetId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
          "gaugeSwatchId":"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
          "method":"manual",
          "washState":"before",
          "measuredWidth":10,
          "measuredHeight":10,
          "rawStitches":22,
          "rawRows":30,
          "normalizedStitches":22,
          "normalizedRows":30,
          "finalStitches":22,
          "finalRows":30,
          "autoStitches":0,
          "autoRows":0,
          "autoConfidence":null,
          "userModified":false,
          "photoPath":null,
          "cornerCoordinates":null,
          "createdAt":"2026-07-09T03:02:00.000Z",
          "updatedAt":"2026-07-09T03:02:00.000Z",
          "deletedAt":null,
          "syncStatus":"Synced"
        }]
      }]
    }]
    """
}
