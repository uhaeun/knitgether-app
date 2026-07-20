//
//  KnitGetherUITestCase.swift
//  KnitGetherUITests
//

import XCTest

class KnitGetherUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        addUIInterruptionMonitor(withDescription: "System password prompt") { alert in
            let dismissButtonTitles = [
                "Not Now",
                "나중에",
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
        apiBaseURL: String = "http://127.0.0.1:3000/api/v1",
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
        apiBaseURL: String = "http://127.0.0.1:3000/api/v1",
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

    private func launchEnvironment(
        apiBaseURL: String,
        resetOnboarding: Bool,
        localCacheDirectory: URL?,
        localCacheRootDirectory: URL?
    ) -> [String: String] {
        var environment = [
            "KNITGETHER_API_BASE_URL": apiBaseURL,
            "KNITGETHER_DEV_AUTH_TOKEN": ""
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
