//
//  UITestPage.swift
//  KnitGetherUITests
//

import XCTest

@MainActor
protocol UITestPage {
    var app: XCUIApplication { get }

    init(app: XCUIApplication)
}

extension UITestPage {
    func anyElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    func tap(
        _ element: XCUIElement,
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected element to exist: \(element)",
            file: file,
            line: line
        )

        if !element.isHittable, app.keyboards.element.exists {
            dismissKeyboard()
            _ = app.keyboards.element.waitForNonExistence(timeout: 2)
        }

        if !element.isHittable {
            for _ in 0..<8 where !element.isHittable {
                scrollToward(element)
            }
        }

        XCTAssertTrue(
            element.isHittable,
            "Expected element to be hittable: \(element)",
            file: file,
            line: line
        )
        element.tap()
    }

    func enterText(
        _ identifier: String,
        text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = inputElement(identifier)
        tap(element, file: file, line: line)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        element.typeText(text)
    }

    private func inputElement(_ identifier: String) -> XCUIElement {
        let textField = app.textFields[identifier].firstMatch
        if textField.waitForExistence(timeout: 1) {
            return textField
        }

        let secureField = app.secureTextFields[identifier].firstMatch
        if secureField.waitForExistence(timeout: 1) {
            return secureField
        }

        let textView = app.textViews[identifier].firstMatch
        if textView.waitForExistence(timeout: 1) {
            return textView
        }

        return anyElement(identifier)
    }

    private func scrollToward(_ element: XCUIElement) {
        let appFrame = app.frame
        let keyboardTop = app.keyboards.element.exists ? app.keyboards.element.frame.minY : appFrame.maxY
        let visibleTop = appFrame.minY + 120
        let visibleBottom = keyboardTop - 24

        if element.frame.midY < visibleTop {
            dragScroll(up: false)
        } else if element.frame.midY > visibleBottom {
            dragScroll(up: true)
        } else {
            dragScroll(up: true)
        }
    }

    private func dragScroll(up: Bool) {
        let appFrame = app.frame
        let keyboardTop = app.keyboards.element.exists ? app.keyboards.element.frame.minY : appFrame.maxY
        let upperY = appFrame.minY + 220
        let lowerY = min(appFrame.maxY - 120, keyboardTop - 40)
        let startY = up ? lowerY : upperY
        let endY = up ? upperY : lowerY
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: appFrame.midX, dy: startY))
        let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: appFrame.midX, dy: endY))

        if abs(startY - endY) > 20 {
            start.press(forDuration: 0.05, thenDragTo: end)
        } else {
            app.swipeUp()
        }
    }

    func dismissKeyboard() {
        guard app.keyboards.element.exists else {
            return
        }

        if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        } else if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.14)).tap()
        }
    }

    func expectText(
        _ text: String,
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts[text].waitForExistence(timeout: timeout),
            "Expected text to exist: \(text)",
            file: file,
            line: line
        )
    }
}
