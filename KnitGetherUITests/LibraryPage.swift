//
//  LibraryPage.swift
//  KnitGetherUITests
//

import XCTest

struct LibraryPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> LibraryPage {
        XCTAssertTrue(
            app.navigationBars["창고"].waitForExistence(timeout: 12),
            "창고 화면이 보여야 합니다."
        )
        return self
    }

    func openYarnLibrary() -> YarnLibraryPage {
        tap(app.staticTexts["실 창고"].firstMatch)
        return YarnLibraryPage(app: app)
    }

    func openNeedleLibrary() -> NeedleLibraryPage {
        tap(app.staticTexts["바늘 창고"].firstMatch)
        return NeedleLibraryPage(app: app)
    }

    func openToolLibrary() -> ToolLibraryPage {
        tap(app.staticTexts["도구 창고"].firstMatch)
        return ToolLibraryPage(app: app)
    }
}
