//
//  KnitGetherUITestCase.swift
//  KnitGetherUITests
//

import XCTest

class KnitGetherUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        addUIInterruptionMonitor(withDescription: "Local network access for isolated test server") { alert in
            let text = alert.label + " " + alert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
            guard text.localizedCaseInsensitiveContains("local network") || text.contains("로컬 네트워크") else {
                return false
            }
            for title in ["허용", "Allow", "OK", "확인"] {
                let button = alert.buttons[title].firstMatch
                if button.exists { button.tap(); return true }
            }
            return false
        }
        addUIInterruptionMonitor(withDescription: "System password prompt") { alert in
            let dismissButtonTitles = [
                "Not Now",
                "나중에",
                "지금 안 함",
                "Don't Save",
                "저장 안 함",
                "Cancel",
                "취소"
            ]

            for title in dismissButtonTitles {
                let button = alert.buttons[title].firstMatch
                if button.exists {
                    button.tap()
                    return true
                }
            }

            return false
        }
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
        apiBaseURL: String = ProcessInfo.processInfo.environment["KG_API_BASE_URL"] ?? "http://127.0.0.1:3000/api/v1",
        localCacheDirectory: URL? = nil,
        localCacheRootDirectory: URL? = nil
    ) -> OnboardingPage {
        app.launchArguments = [
            "-ApplePersistenceIgnoreState",
            "YES"
        ]
        app.launchEnvironment = launchEnvironment(
            apiBaseURL: apiBaseURL,
            resetOnboarding: true,
            localCacheDirectory: localCacheDirectory,
            localCacheRootDirectory: localCacheRootDirectory
        )
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return OnboardingPage(app: app)
    }

    @MainActor
    func relaunchForExistingSession(
        apiBaseURL: String = ProcessInfo.processInfo.environment["KG_API_BASE_URL"] ?? "http://127.0.0.1:3000/api/v1",
        localCacheDirectory: URL? = nil,
        localCacheRootDirectory: URL? = nil
    ) -> MainTabBarPage {
        if app.state != .notRunning {
            app.terminate()
        }

        app.launchArguments = [
            "-ApplePersistenceIgnoreState",
            "YES"
        ]
        app.launchEnvironment = launchEnvironment(
            apiBaseURL: apiBaseURL,
            resetOnboarding: false,
            localCacheDirectory: localCacheDirectory,
            localCacheRootDirectory: localCacheRootDirectory
        )
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let mainTabs = MainTabBarPage(app: app)
        mainTabs.expectVisible()
        return mainTabs
    }

    func makeLocalCacheDirectory(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KnitGetherUITests-\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @MainActor
    func dismissCameraDenialGuidance() {
        let scannerAlert = app.alerts.firstMatch
        if scannerAlert.waitForExistence(timeout: 8), scannerAlert.buttons["Settings"].exists {
            let text = scannerAlert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
            XCTAssertTrue(text.localizedCaseInsensitiveContains("camera"))
            scannerAlert.buttons["OK"].tap()
            let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "취소", "Close", "닫기"])).firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 5))
            cancel.tap()
        }
        let message = "카메라 접근이 꺼져 있어요. iPhone 설정에서 이 앱의 카메라를 허용해 주세요."
        let alert = app.alerts.containing(.staticText, identifier: message).firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 12))
        let text = alert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(text.contains("카메라") && text.contains("설정"))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Camera denial guidance before returning"
        attachment.lifetime = .keepAlways
        add(attachment)
        alert.buttons["확인"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 8))
    }

    private func launchEnvironment(
        apiBaseURL: String,
        resetOnboarding: Bool,
        localCacheDirectory: URL?,
        localCacheRootDirectory: URL?
    ) -> [String: String] {
        var environment = [
            "KNITGETHER_API_BASE_URL": apiBaseURL,
            "KNITGETHER_DISABLE_DEV_AUTH_TOKEN": "1"
        ]

        if resetOnboarding {
            environment["KNITGETHER_UI_TEST_RESET_ONBOARDING"] = "1"
        }

        if let localCacheDirectory {
            environment["KNITGETHER_LOCAL_CACHE_DIRECTORY"] = localCacheDirectory.path
        }

        if let localCacheRootDirectory {
            environment["KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY"] = localCacheRootDirectory.path
        }

        return environment
    }

    @MainActor
    func launchDefault() {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
