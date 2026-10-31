import XCTest

#if !targetEnvironment(simulator)
/// Account-free local flows remain testable independently of LAN permissions.
final class DeviceLocalFlowTests: KnitGetherUITestCase {
    private let unavailableAPI = "http://127.0.0.1:1/api/v1"

    @MainActor
    func testGuestCounterSurvivesBackgroundAndRelaunch() throws {
        let (name, workspace) = makeGuestProject(prefix: "Device Local Counter")
        workspace.advanceRow().expectCurrentRow(1)
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.activate()
        workspace.expectCurrentRow(1)
        relaunchForExistingSession(apiBaseURL: unavailableAPI)
            .openMyKnitting().openProject(named: name).expectCurrentRow(1)
        keepScreenshot(named: "Guest counter after background and relaunch")
    }

    @MainActor
    func testGuestCameraDenialReturnsToWorkspace() throws {
        app.resetAuthorizationStatus(for: .camera)
        let (_, workspace) = makeGuestProject(prefix: "Device Local Camera")
        workspace.advanceRow().expectCurrentRow(1)
        let counterToggle = app.buttons["workspace.counter.sheet_toggle"]
        if counterToggle.label.contains("접기") { counterToggle.tap() }
        app.buttons["workspace.pattern.focus.menu"].tap()
        let scan = app.buttons["workspace.pattern.scan"]
        XCTAssertTrue(scan.waitForExistence(timeout: 8))
        scan.tap()

        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 15))
        let text = alert.label + " " + alert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(text.contains("카메라") || text.localizedCaseInsensitiveContains("camera"))
        let deny = alert.buttons.matching(NSPredicate(format: "label IN %@", ["허용 안 함", "허용안함", "Don't Allow", "Don’t Allow"])).firstMatch
        XCTAssertTrue(deny.exists)
        deny.tap()

        dismissCameraDenialGuidance()
        workspace.expectCurrentRow(1)
        keepScreenshot(named: "Guest workspace after camera denial")
    }

    @MainActor
    private func makeGuestProject(prefix: String) -> (String, WorkspacePage) {
        let onboarding = launchForCoreFlow(apiBaseURL: unavailableAPI)
        tapNextOnIntro()
        let tabs = onboarding.advanceToSkillTestStep().finishOnboarding()
        let name = "\(prefix) \(UUID().uuidString.prefix(6))"
        tabs.openMyKnitting().openAddProject().saveProject(named: name).expectProjectSaved(named: name)
        return (name, tabs.openMyKnitting().openProject(named: name))
    }

    @MainActor
    private func tapNextOnIntro() {
        let next = app.buttons["다음"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.tap()
    }

    @MainActor
    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
