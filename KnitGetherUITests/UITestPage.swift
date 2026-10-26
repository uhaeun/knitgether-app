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

        // Password AutoFill can present its save prompt after authentication has
        // already finished. Handle it before the hittability assertion; otherwise
        // that assertion prevents XCTest's interruption monitor from getting a tap.
        if !element.isHittable {
            dismissSystemPasswordPromptIfNeeded()
        }

        if !element.isHittable, app.keyboards.element.exists {
            dismissKeyboard()
            _ = app.keyboards.element.waitForNonExistence(timeout: 2)
        }

        if !element.isHittable {
            for _ in 0..<8 where !element.isHittable {
                scrollToward(element)
            }
        }

        // A delayed system prompt can also arrive during keyboard/scroll work.
        if !element.isHittable {
            dismissSystemPasswordPromptIfNeeded()
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

    func replaceText(
        _ identifier: String,
        text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = inputElement(identifier)
        tap(element, file: file, line: line)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // A single burst of delete keys is not reliable — long values (and TextViews
        // especially) silently drop some, leaving a prefix behind that the new text
        // then gets appended to. Delete in rounds and re-read the value until it stops
        // shrinking. An empty field reports its placeholder as `value`, so the
        // "unchanged since last round" check is what terminates the loop there.
        var previousValue: String?

        for _ in 0..<10 {
            guard let currentValue = element.value as? String,
                  !currentValue.isEmpty,
                  currentValue != previousValue
            else {
                break
            }

            previousValue = currentValue
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        }

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
        } else if app.keyboards.buttons["완료"].exists {
            app.keyboards.buttons["완료"].firstMatch.tap()
        } else if app.buttons["완료"].exists {
            app.buttons["완료"].firstMatch.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.14)).tap()
        }
        // Do not let the next form operation tap a keyboard that is animating away.
        _ = app.keyboards.firstMatch.waitForNonExistence(timeout: 3)
    }

    func dismissSystemPasswordPromptIfNeeded(timeout: TimeInterval = 2) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let candidates = [
            springboard.buttons["Not Now"].firstMatch,
            springboard.buttons["나중에"].firstMatch,
            springboard.buttons["지금 안 함"].firstMatch,
            springboard.buttons["Don't Save"].firstMatch,
            springboard.buttons["저장 안 함"].firstMatch,
            app.buttons["Not Now"].firstMatch,
            app.buttons["나중에"].firstMatch,
            app.buttons["지금 안 함"].firstMatch,
            app.buttons["Don't Save"].firstMatch,
            app.buttons["저장 안 함"].firstMatch
        ]

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let button = candidates.first(where: { $0.exists && $0.isHittable }) {
                XCTContext.runActivity(named: "Dismiss system password save prompt") { activity in
                    let before = XCTAttachment(screenshot: app.screenshot())
                    before.name = "Password prompt before dismissal"
                    before.lifetime = .keepAlways
                    activity.add(before)
                    button.tap()
                    XCTAssertTrue(button.waitForNonExistence(timeout: 5),
                                  "System password prompt must disappear before continuing")
                    let after = XCTAttachment(screenshot: app.screenshot())
                    after.name = "Password prompt after dismissal"
                    after.lifetime = .keepAlways
                    activity.add(after)
                }
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        // An unrelated system modal is not permission to tap a guessed coordinate.
        // Leave unknown interruptions visible so the caller fails with evidence.
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
