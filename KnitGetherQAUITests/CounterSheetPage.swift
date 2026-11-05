import XCTest

struct CounterSheetPage {
    let app: XCUIApplication

    func expectValue(_ expected: String) {
        let counterValue = app.staticTexts["workspace.counter.current"]
        XCTAssertTrue(counterValue.waitForExistence(timeout: 5))
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expected), object: counterValue
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        XCTAssertEqual(counterValue.label, expected)
    }

    func editCurrent(_ text: String) {
        openEditor("workspace.counter.edit_current")
        replaceNumber(text)
    }

    func editTarget(_ text: String) {
        openEditor("workspace.counter.edit_target")
        replaceNumber(text)
    }

    func replaceNumber(_ text: String) {
        let field = app.textFields["workspace.counter.number_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        if !text.isEmpty { field.typeText(text) }
    }

    func expectRejectedInput(_ text: String) {
        let error = app.descendants(matching: .any)["workspace.counter.number_error"].firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("기존 단수는 유지돼요"))
        let field = app.textFields["workspace.counter.number_field"]
        XCTAssertTrue(field.exists, "잘못된 입력은 수정할 수 있도록 입력창에 남아야 한다.")
        if !text.isEmpty { XCTAssertEqual(field.value as? String, text) }
        XCTAssertFalse(app.buttons["workspace.counter.number_save"].isEnabled)
    }

    func saveNumber() {
        let save = app.buttons["workspace.counter.number_save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["workspace.counter.number_error"].firstMatch.exists)
        save.tap()
        XCTAssertTrue(app.textFields["workspace.counter.number_field"].waitForNonExistence(timeout: 5))
    }

    func cancelNumber() {
        app.buttons["workspace.counter.number_cancel"].tap()
        XCTAssertTrue(app.textFields["workspace.counter.number_field"].waitForNonExistence(timeout: 5))
    }

    func expectTarget(_ target: String) {
        openEditor("workspace.counter.edit_target")
        XCTAssertEqual(app.textFields["workspace.counter.number_field"].value as? String, target)
        cancelNumber()
    }

    private func openEditor(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<5 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(app.textFields["workspace.counter.number_field"].waitForExistence(timeout: 5))
    }

    func close() {
        app.buttons["workspace.counter.sheet_toggle"].tap()
    }
}
