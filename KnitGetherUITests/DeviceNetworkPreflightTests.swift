import Foundation
import XCTest

#if !targetEnvironment(simulator)
/// Test preparation for a physical device using a separate LAN test server.
/// This does not count as a user-flow test.
final class DeviceNetworkPreflightTests: XCTestCase {
    func testRunnerCanReachConfiguredServer() async throws {
        let baseURL = try XCTUnwrap(ProcessInfo.processInfo.environment["KG_API_BASE_URL"])
        let url = try XCTUnwrap(URL(string: baseURL + "/projects"))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        do {
            let (_, response) = try await session.data(from: url)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
            return
        } catch {
            let networkError = error as NSError
            guard networkError.domain == NSURLErrorDomain,
                  networkError.code == NSURLErrorNotConnectedToInternet else { throw error }
        }

        // The runner has its own permission. A background request may fail
        // without showing its prompt even when the app has LAN access.
        let bundleID = try XCTUnwrap(Bundle.main.bundleIdentifier)
        XCTAssertTrue(bundleID.hasSuffix(".xctrunner"))
        let runner = XCUIApplication(bundleIdentifier: bundleID)
        runner.activate()
        let probe = session.dataTask(with: url)
        probe.resume()
        defer { probe.cancel() }

        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if alert.waitForExistence(timeout: 10) {
            let text = alert.label + " " + alert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
            guard text.contains("로컬 네트워크") || text.localizedCaseInsensitiveContains("local network") else {
                XCTFail("An unexpected system prompt blocks the runner network preflight.")
                return
            }
            let allow = alert.buttons.matching(NSPredicate(format: "label IN %@", ["허용", "Allow", "OK", "확인"])).firstMatch
            XCTAssertTrue(allow.exists)
            if allow.exists { allow.tap() }
        }

        let (_, response) = try await session.data(from: url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
    }
}
#endif
