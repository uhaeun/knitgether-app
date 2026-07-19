//
//  KnitGetherUITestCase.swift
//  KnitGetherUITests
//

import XCTest

class KnitGetherUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let testRun, testRun.failureCount > 0 {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Failure Screenshot"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor
    func launchForCoreFlow(
        apiBaseURL: String = "http://127.0.0.1:3000/api/v1"
    ) -> OnboardingPage {
        app.launchArguments = [
            "-ApplePersistenceIgnoreState",
            "YES"
        ]
        app.launchEnvironment = [
            "KNITGETHER_API_BASE_URL": apiBaseURL,
            "KNITGETHER_DEV_AUTH_TOKEN": "",
            "KNITGETHER_UI_TEST_RESET_ONBOARDING": "1"
        ]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return OnboardingPage(app: app)
    }

    @MainActor
    func launchDefault() {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
