//
//  MainTabBarPage.swift
//  KnitGetherUITests
//

import XCTest

struct MainTabBarPage: UITestPage {
    let app: XCUIApplication

    func expectVisible() {
        XCTAssertTrue(app.tabBars.buttons["내 뜨개"].waitForExistence(timeout: 12))
    }

    func openMyKnitting() -> MyKnittingPage {
        let page = MyKnittingPage(app: app)

        for _ in 0..<3 {
            if app.navigationBars["나의 뜨개"].exists || app.buttons["project.add"].exists {
                return page
            }

            let tabButton = app.tabBars.buttons["내 뜨개"].firstMatch
            if tabButton.waitForExistence(timeout: 4) {
                tap(tabButton)
            } else {
                tap(app.buttons["heart.text.square.fill"].firstMatch)
            }

            if app.navigationBars["나의 뜨개"].waitForExistence(timeout: 4)
                || app.buttons["project.add"].waitForExistence(timeout: 4) {
                return page
            }
        }

        page.expectVisible()
        return page
    }

    func openTools() -> ToolPage {
        tap(app.tabBars.buttons["도구"].firstMatch)
        return ToolPage(app: app)
    }

    func openSettings() -> SettingsPage {
        tap(app.tabBars.buttons["설정"].firstMatch)
        return SettingsPage(app: app)
    }
}
