//
//  SettingsPage.swift
//  KnitGetherUITests
//

import XCTest

struct SettingsPage: UITestPage {
    let app: XCUIApplication

    func openAccount() -> AuthPage {
        tap(app.buttons["settings.account"].firstMatch)
        let account = AuthPage(app: app)
        account.expectVisible()
        return account
    }

    func openProfile() -> SettingsPage {
        tap(app.buttons["settings.profile"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["프로필 / 설정"].waitForExistence(timeout: 12),
            "프로필 / 설정 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func expectProfileLoadErrorNotVisible() -> SettingsPage {
        XCTAssertFalse(
            app.staticTexts["프로필을 불러오지 못했어요."].waitForExistence(timeout: 5),
            "로그아웃 직후 프로필 로드 오류가 보이면 안 됩니다."
        )
        return self
    }
}
