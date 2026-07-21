//
//  YarnLibraryPage.swift
//  KnitGetherUITests
//

import XCTest

struct YarnLibraryPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> YarnLibraryPage {
        XCTAssertTrue(
            app.navigationBars["실 창고"].waitForExistence(timeout: 12),
            "실 창고 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func addYarn(name: String, brand: String = "", colorway: String = "") -> YarnLibraryPage {
        tap(app.buttons["library.yarn.add"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["실 추가"].waitForExistence(timeout: 12),
            "실 추가 화면이 보여야 합니다."
        )

        enterText("library.yarn.form.name", text: name)
        dismissKeyboard()

        if !brand.isEmpty {
            enterText("library.yarn.form.brand", text: brand)
            dismissKeyboard()
        }

        if !colorway.isEmpty {
            enterText("library.yarn.form.colorway", text: colorway)
            dismissKeyboard()
        }

        tap(app.buttons["library.yarn.save"])
        return self
    }

    @discardableResult
    func expectYarnVisible(named yarnName: String) -> YarnLibraryPage {
        XCTAssertTrue(
            app.staticTexts[yarnName].waitForExistence(timeout: 12),
            "저장된 실이 목록에 보여야 합니다: \(yarnName)"
        )
        return self
    }

    @discardableResult
    func expectYarnNotVisible(named yarnName: String) -> YarnLibraryPage {
        XCTAssertFalse(
            app.staticTexts[yarnName].waitForExistence(timeout: 5),
            "삭제한 실이 목록에 보이면 안 됩니다: \(yarnName)"
        )
        return self
    }

    func openYarn(named yarnName: String) -> YarnLibraryPage {
        tap(app.staticTexts[yarnName].firstMatch)
        XCTAssertTrue(
            app.navigationBars["실 상세"].waitForExistence(timeout: 12),
            "실 상세 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func editYarn(name: String) -> YarnLibraryPage {
        tap(app.buttons["library.yarn.edit"])
        XCTAssertTrue(
            app.navigationBars["실 수정"].waitForExistence(timeout: 12),
            "실 수정 화면이 보여야 합니다."
        )

        replaceText("library.yarn.form.name", text: name)
        dismissKeyboard()

        tap(app.buttons["library.yarn.save"])
        XCTAssertTrue(
            app.navigationBars["실 상세"].waitForExistence(timeout: 12),
            "수정 저장 후 실 상세 화면으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func deleteYarn() -> YarnLibraryPage {
        tap(app.buttons["library.yarn.delete"])
        XCTAssertTrue(
            app.alerts["실을 삭제할까요?"].waitForExistence(timeout: 12),
            "삭제 확인 알림이 보여야 합니다."
        )
        tap(app.alerts.buttons["삭제"].firstMatch)
        return self
    }

    func returnToLibrary() -> LibraryPage {
        if app.navigationBars.buttons["닫기"].waitForExistence(timeout: 4) {
            tap(app.navigationBars.buttons["닫기"].firstMatch)
        }

        if app.navigationBars.buttons["창고"].waitForExistence(timeout: 4) {
            tap(app.navigationBars.buttons["창고"].firstMatch)
        }

        return LibraryPage(app: app)
    }
}
