//
//  AuthPage.swift
//  KnitGetherUITests
//

import XCTest

struct AuthPage: UITestPage {
    let app: XCUIApplication

    func signOutIfNeeded() -> AuthPage {
        let logoutButton = app.buttons["auth.logout"].exists
            ? app.buttons["auth.logout"]
            : app.buttons["로그아웃"].firstMatch

        if logoutButton.waitForExistence(timeout: 2) {
            tap(logoutButton)
        }

        return self
    }

    func register(
        email: String,
        password: String,
        displayName: String
    ) -> AuthPage {
        tap(app.buttons["회원가입"].firstMatch)
        enterText("auth.email", text: email)
        dismissKeyboard()
        enterText("auth.display_name", text: displayName)
        dismissKeyboard()
        enterText("auth.password", text: password)
        dismissKeyboard()
        tap(app.buttons["auth.submit"].firstMatch)
        return self
    }

    func expectRegistrationCompleted() {
        XCTAssertTrue(
            app.staticTexts["회원가입이 완료됐어요."].waitForExistence(timeout: 12)
                || app.buttons["auth.logout"].waitForExistence(timeout: 12),
            "회원가입 후 성공 메시지 또는 로그인 상태가 표시되어야 합니다."
        )
    }

    func returnToOnboarding() -> OnboardingPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        return OnboardingPage(app: app)
    }
}
