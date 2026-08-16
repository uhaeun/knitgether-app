import XCTest

struct CounterSheetPage {
    let app: XCUIApplication

    func expectValue(_ expected: String) {
        let counterValue = app.staticTexts["workspace.counter.current"]
        XCTAssertTrue(counterValue.waitForExistence(timeout: 5))
        XCTAssertEqual(counterValue.label, expected)
    }

    func close() {
        app.buttons["workspace.counter.sheet_toggle"].tap()
    }
}
