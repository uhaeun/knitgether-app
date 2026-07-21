//
//  NeedleLibraryPage.swift
//  KnitGetherUITests
//

import XCTest

struct NeedleLibraryPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> NeedleLibraryPage {
        XCTAssertTrue(
            app.navigationBars["바늘 창고"].waitForExistence(timeout: 12),
            "바늘 창고 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func addNeedle(name: String, size: String = "") -> NeedleLibraryPage {
        tap(app.buttons["library.needle.add"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["바늘 추가"].waitForExistence(timeout: 12),
            "바늘 추가 화면이 보여야 합니다."
        )

        enterText("library.needle.form.name", text: name)
        dismissKeyboard()

        if !size.isEmpty {
            enterText("library.needle.form.size", text: size)
            dismissKeyboard()
        }

        tap(app.buttons["library.needle.save"])
        return self
    }

    @discardableResult
    func expectNeedleVisible(named needleName: String) -> NeedleLibraryPage {
        XCTAssertTrue(
            app.staticTexts[needleName].waitForExistence(timeout: 12),
            "저장된 바늘이 목록에 보여야 합니다: \(needleName)"
        )
        return self
    }

    @discardableResult
    func expectNeedleNotVisible(named needleName: String) -> NeedleLibraryPage {
        XCTAssertFalse(
            app.staticTexts[needleName].waitForExistence(timeout: 5),
            "삭제한 바늘이 목록에 보이면 안 됩니다: \(needleName)"
        )
        return self
    }

    func openNeedle(named needleName: String) -> NeedleLibraryPage {
        tap(app.staticTexts[needleName].firstMatch)
        XCTAssertTrue(
            app.navigationBars["바늘 상세"].waitForExistence(timeout: 12),
            "바늘 상세 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func editNeedle(name: String) -> NeedleLibraryPage {
        tap(app.buttons["library.needle.edit"])
        XCTAssertTrue(
            app.navigationBars["바늘 수정"].waitForExistence(timeout: 12),
            "바늘 수정 화면이 보여야 합니다."
        )

        replaceText("library.needle.form.name", text: name)
        dismissKeyboard()

        tap(app.buttons["library.needle.save"])
        XCTAssertTrue(
            app.navigationBars["바늘 상세"].waitForExistence(timeout: 12),
            "수정 저장 후 바늘 상세 화면으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func deleteNeedle() -> NeedleLibraryPage {
        tap(app.buttons["library.needle.delete"])
        XCTAssertTrue(
            app.alerts["바늘을 삭제할까요?"].waitForExistence(timeout: 12),
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
