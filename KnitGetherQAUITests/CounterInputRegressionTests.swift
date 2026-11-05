import XCTest

/// 2026-11-05 정책 검토: 잘못된 직접 입력은 저장을 막고 기존 단수를 보존한다.
final class CounterInputRegressionTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-knitgether.onboardingCompleted", "YES"]
        app.launchEnvironment["KNITGETHER_API_BASE_URL"] = ""
        app.launch()
    }

    override func tearDownWithError() throws {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }

    @MainActor
    func testNegativeCurrentRowPreserves25AcrossRelaunchAndCanBeCorrected() {
        let (name, counter) = createProject()
        counter.editCurrent("25")
        counter.saveNumber()
        counter.expectValue("현재 25단")

        counter.editCurrent("-1")
        counter.expectRejectedInput("-1")
        counter.cancelNumber()
        counter.expectValue("현재 25단")

        let reopened = reopenProject(name)
        reopened.expectValue("현재 25단")
        reopened.editCurrent("-1")
        reopened.expectRejectedInput("-1")
        reopened.replaceNumber("26")
        reopened.saveNumber()
        reopened.expectValue("현재 26단")
        reopenProject(name).expectValue("현재 26단")
    }

    @MainActor
    func testZeroAndOnePersistAfterInvalidInputIsCorrected() {
        let (name, counter) = createProject()
        counter.editCurrent("25")
        counter.saveNumber()
        counter.expectValue("현재 25단")

        counter.editCurrent("")
        counter.expectRejectedInput("")
        counter.replaceNumber("0")
        counter.saveNumber()
        counter.expectValue("시작 전")

        let reopened = reopenProject(name)
        reopened.expectValue("시작 전")
        reopened.editCurrent("1")
        reopened.saveNumber()
        reopened.expectValue("현재 1단")
        reopenProject(name).expectValue("현재 1단")
    }

    @MainActor
    func testNegativeTargetDoesNotUnsetItAndZeroStillDoes() {
        let (name, counter) = createProject()
        counter.editTarget("100")
        counter.saveNumber()
        counter.expectTarget("100")

        counter.editTarget("-1")
        counter.expectRejectedInput("-1")
        counter.cancelNumber()
        counter.expectTarget("100")

        let reopened = reopenProject(name)
        reopened.expectTarget("100")
        reopened.editTarget("0")
        reopened.saveNumber()
        reopened.expectTarget("0")
        reopenProject(name).expectTarget("0")
    }

    @MainActor
    private func createProject() -> (String, CounterSheetPage) {
        let name = "Counter-\(UUID().uuidString.prefix(8))"
        let list = MyKnittingPage(app: app)
        list.open()
        _ = list.createProject(named: name)
        return (name, openCounter())
    }

    @MainActor
    private func reopenProject(_ name: String) -> CounterSheetPage {
        app.terminate()
        app.launch()
        MyKnittingPage(app: app).open()
        let row = app.staticTexts[name]
        for _ in 0..<5 {
            if row.exists && row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.isHittable)
        row.tap()
        return openCounter()
    }

    @MainActor
    private func openCounter() -> CounterSheetPage {
        let toggle = app.buttons["workspace.counter.sheet_toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if !app.descendants(matching: .any)["workspace.counter.mode"].firstMatch.exists {
            toggle.tap()
        }
        XCTAssertTrue(app.staticTexts["workspace.counter.current"].waitForExistence(timeout: 5))
        return CounterSheetPage(app: app)
    }
}
