//
//  ToolLibraryPage.swift
//  KnitGetherUITests
//

import XCTest

struct ToolLibraryPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> ToolLibraryPage {
        XCTAssertTrue(
            app.navigationBars["도구 창고"].waitForExistence(timeout: 12),
            "도구 창고 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func addTool(name: String, type: String = "") -> ToolLibraryPage {
        tap(app.buttons["library.tool.add"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["도구 추가"].waitForExistence(timeout: 12),
            "도구 추가 화면이 보여야 합니다."
        )

        enterText("library.tool.form.name", text: name)
        dismissKeyboard()

        if !type.isEmpty {
            enterText("library.tool.form.type", text: type)
            dismissKeyboard()
        }

        tap(app.buttons["library.tool.save"])
        return self
    }

    @discardableResult
    func expectToolVisible(named toolName: String) -> ToolLibraryPage {
        XCTAssertTrue(
            app.staticTexts[toolName].waitForExistence(timeout: 12),
            "저장된 도구가 목록에 보여야 합니다: \(toolName)"
        )
        return self
    }

    @discardableResult
    func expectToolNotVisible(named toolName: String) -> ToolLibraryPage {
        XCTAssertFalse(
            app.staticTexts[toolName].waitForExistence(timeout: 5),
            "삭제한 도구가 목록에 보이면 안 됩니다: \(toolName)"
        )
        return self
    }

    func openTool(named toolName: String) -> ToolLibraryPage {
        tap(app.staticTexts[toolName].firstMatch)
        XCTAssertTrue(
            app.navigationBars["도구 상세"].waitForExistence(timeout: 12),
            "도구 상세 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func editTool(name: String) -> ToolLibraryPage {
        tap(app.buttons["library.tool.edit"])
        XCTAssertTrue(
            app.navigationBars["도구 수정"].waitForExistence(timeout: 12),
            "도구 수정 화면이 보여야 합니다."
        )

        replaceText("library.tool.form.name", text: name)
        dismissKeyboard()

        tap(app.buttons["library.tool.save"])
        XCTAssertTrue(
            app.navigationBars["도구 상세"].waitForExistence(timeout: 12),
            "수정 저장 후 도구 상세 화면으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func deleteTool() -> ToolLibraryPage {
        tap(app.buttons["library.tool.delete"])
        XCTAssertTrue(
            app.alerts["도구를 삭제할까요?"].waitForExistence(timeout: 12),
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
