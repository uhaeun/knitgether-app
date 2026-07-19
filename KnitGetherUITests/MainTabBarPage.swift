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
        tap(app.tabBars.buttons["내 뜨개"].firstMatch)
        return MyKnittingPage(app: app)
    }

    func openTools() -> ToolPage {
        tap(app.tabBars.buttons["도구"].firstMatch)
        return ToolPage(app: app)
    }
}
