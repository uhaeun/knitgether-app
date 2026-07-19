//
//  AuthPage.swift
//  KnitGetherUITests
//

import XCTest

struct AuthPage: UITestPage {
    let app: XCUIApplication

    func expectVisible() {
        XCTAssertTrue(
            app.navigationBars["계정"].waitForExistence(timeout: 12),
            "계정 화면이 보여야 합니다."
        )
    }

    func signOutIfNeeded() -> AuthPage {
        let identifierButton = app.buttons["auth.logout"].firstMatch
        if identifierButton.waitForExistence(timeout: 5) {
            tap(identifierButton)
            reopenAccountFormIfNeeded()
            return self
        }

        let labelButton = app.buttons["로그아웃"].firstMatch
        if labelButton.waitForExistence(timeout: 2) {
            tap(labelButton)
            reopenAccountFormIfNeeded()
        }

        return self
    }

    func register(
        email: String,
        password: String,
        displayName: String
    ) -> AuthPage {
        expectVisible()
        tap(app.buttons["회원가입"].firstMatch)
        enterText("auth.email", text: email)
        dismissKeyboard()
        enterText("auth.display_name", text: displayName)
        dismissKeyboard()
        enterText("auth.password", text: password)
        dismissKeyboard()
        let submitButton = app.buttons["auth.submit"].firstMatch
        XCTAssertTrue(
            submitButton.waitForExistence(timeout: 12) && submitButton.isEnabled,
            "회원가입 제출 버튼이 활성화되어야 합니다."
        )
        tap(submitButton)
        return self
    }

    func login(
        email: String,
        password: String
    ) -> AuthPage {
        expectVisible()
        tap(app.buttons["로그인"].firstMatch)
        enterText("auth.email", text: email)
        dismissKeyboard()
        enterText("auth.password", text: password)
        dismissKeyboard()
        let submitButton = app.buttons["auth.submit"].firstMatch
        XCTAssertTrue(
            submitButton.waitForExistence(timeout: 12) && submitButton.isEnabled,
            "로그인 제출 버튼이 활성화되어야 합니다."
        )
        tap(submitButton)
        return self
    }

    @discardableResult
    func expectRegistrationCompleted(displayName: String? = nil) -> AuthPage {
        if let displayName {
            waitForAuthenticationEvidence(
                displayName: displayName,
                successMessage: "회원가입이 완료됐어요.",
                failureMessage: "회원가입 후 성공 메시지 또는 로그인 상태가 표시되어야 합니다."
            )
            return self
        }

        XCTAssertTrue(
            app.staticTexts["회원가입이 완료됐어요."].waitForExistence(timeout: 12)
                || app.buttons["auth.logout"].waitForExistence(timeout: 12),
            "회원가입 후 성공 메시지 또는 로그인 상태가 표시되어야 합니다."
        )
        return self
    }

    @discardableResult
    func expectLoginCompleted(displayName: String? = nil) -> AuthPage {
        if let displayName {
            waitForAuthenticationEvidence(
                displayName: displayName,
                successMessage: "로그인했어요.",
                failureMessage: "로그인 후 성공 메시지 또는 로그인 상태가 표시되어야 합니다."
            )
            return self
        }

        XCTAssertTrue(
            app.staticTexts["로그인했어요."].waitForExistence(timeout: 12)
                || app.buttons["auth.logout"].waitForExistence(timeout: 12),
            "로그인 후 성공 메시지 또는 로그인 상태가 표시되어야 합니다."
        )
        return self
    }

    func returnToOnboarding() -> OnboardingPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        return OnboardingPage(app: app)
    }

    @discardableResult
    func returnToSettings() -> SettingsPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        return SettingsPage(app: app)
    }

    private func reopenAccountFormIfNeeded(
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if app.buttons["auth.submit"].exists {
                return
            }

            if app.buttons["settings.account"].exists {
                tap(app.buttons["settings.account"].firstMatch)
                expectVisible()
                if app.buttons["auth.submit"].waitForExistence(timeout: 4) {
                    return
                }
            }

            if app.tabBars.buttons["설정"].exists {
                tap(app.tabBars.buttons["설정"].firstMatch)
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail(
            "로그아웃 후 로그인/회원가입 폼이 보여야 합니다.",
            file: file,
            line: line
        )
    }

    private func waitForAuthenticationEvidence(
        displayName: String,
        successMessage: String,
        failureMessage: String,
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let accountPageDeadline = Date().addingTimeInterval(timeout)
        while Date() < accountPageDeadline {
            if app.staticTexts[successMessage].exists
                || app.buttons["auth.logout"].exists
                || hasVisibleText(containing: displayName) {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        let visibleText = app.staticTexts.allElementsBoundByIndex
            .map(\.label)
            .prefix(40)
            .joined(separator: " | ")
        XCTFail(
            "\(failureMessage) visibleText=\(visibleText)",
            file: file,
            line: line
        )
    }

    private func hasVisibleText(containing value: String) -> Bool {
        app.staticTexts.allElementsBoundByIndex.contains {
            $0.label.contains(value)
        }
    }
}
