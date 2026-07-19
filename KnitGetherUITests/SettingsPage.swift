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
}
