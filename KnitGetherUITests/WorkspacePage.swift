//
//  WorkspacePage.swift
//  KnitGetherUITests
//

import XCTest

struct WorkspacePage: UITestPage {
    let app: XCUIApplication

    func expectVisible() {
        XCTAssertTrue(
            app.navigationBars["작업 공간"].waitForExistence(timeout: 12)
                || app.staticTexts["단수 카운터"].waitForExistence(timeout: 12),
            "작업 공간 화면이 보여야 합니다."
        )
    }

    @discardableResult
    func advanceRow() -> WorkspacePage {
        tap(app.buttons["workspace.counter.next"].firstMatch)
        return self
    }

    @discardableResult
    func expectCurrentRow(_ row: Int) -> WorkspacePage {
        XCTAssertTrue(
            app.staticTexts["현재 \(row)단"].waitForExistence(timeout: 12)
                || app.staticTexts["\(row)단 · 총 단수 미설정"].waitForExistence(timeout: 12),
            "현재 단수가 \(row)단으로 표시되어야 합니다."
        )
        return self
    }

    @discardableResult
    func enableRowGuideMode() -> WorkspacePage {
        if app.buttons["workspace.row_instruction.add"].exists {
            return self
        }

        tap(app.buttons["행안내 모드"].firstMatch)
        XCTAssertTrue(
            app.buttons["workspace.row_instruction.add"].waitForExistence(timeout: 12),
            "행안내 모드 전환 후 행안내 추가 버튼이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func addRowInstruction(row: Int, text: String, skillTags: String = "") -> WorkspacePage {
        enableRowGuideMode()
        tap(app.buttons["workspace.row_instruction.add"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["행안내 추가"].waitForExistence(timeout: 12),
            "행안내 추가 화면이 보여야 합니다."
        )
        replaceText("workspace.row_instruction.form.number", text: "\(row)")
        enterText("workspace.row_instruction.form.text", text: text)
        dismissKeyboard()
        if !skillTags.isEmpty {
            enterText("workspace.row_instruction.form.skill_tags", text: skillTags)
            dismissKeyboard()
        }
        tap(app.buttons["workspace.row_instruction.form.save"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["작업 공간"].waitForExistence(timeout: 12),
            "행안내 저장 후 작업공간으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func editFirstRowInstruction(row: Int, text: String, skillTags: String = "") -> WorkspacePage {
        tap(app.buttons["행안내 수정"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["행안내 수정"].waitForExistence(timeout: 12),
            "행안내 수정 화면이 보여야 합니다."
        )
        replaceText("workspace.row_instruction.form.number", text: "\(row)")
        replaceText("workspace.row_instruction.form.text", text: text)
        dismissKeyboard()
        if !skillTags.isEmpty {
            replaceText("workspace.row_instruction.form.skill_tags", text: skillTags)
            dismissKeyboard()
        }
        tap(app.buttons["workspace.row_instruction.form.save"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["작업 공간"].waitForExistence(timeout: 12),
            "행안내 수정 후 작업공간으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func deleteFirstRowInstruction() -> WorkspacePage {
        tap(app.buttons["행안내 삭제"].firstMatch)
        let alert = app.alerts["행안내를 삭제할까요?"].firstMatch
        XCTAssertTrue(
            alert.waitForExistence(timeout: 12),
            "행안내 삭제 확인 alert가 보여야 합니다."
        )
        tap(alert.buttons["삭제"].firstMatch)
        return self
    }

    @discardableResult
    func expectRowInstruction(text: String) -> WorkspacePage {
        XCTAssertTrue(
            waitForStaticText(text),
            "행안내가 보여야 합니다: \(text)"
        )
        return self
    }

    @discardableResult
    func expectRowInstructionNotVisible(text: String) -> WorkspacePage {
        XCTAssertFalse(
            app.staticTexts[text].waitForExistence(timeout: 5),
            "삭제되거나 수정된 행안내가 보이면 안 됩니다: \(text)"
        )
        return self
    }

    func openEditProject() -> ProjectFormPage {
        tap(app.buttons["workspace.project.edit"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["프로젝트 수정"].waitForExistence(timeout: 12),
            "프로젝트 수정 화면이 보여야 합니다."
        )
        return ProjectFormPage(app: app)
    }

    func returnToMyKnitting() -> MyKnittingPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        XCTAssertTrue(
            app.navigationBars["나의 뜨개"].waitForExistence(timeout: 12)
                || app.tabBars.buttons["내 뜨개"].waitForExistence(timeout: 12),
            "내 뜨개 목록으로 돌아와야 합니다."
        )
        return MyKnittingPage(app: app)
    }

    @discardableResult
    func expectWorkTimerRunning() -> WorkspacePage {
        XCTAssertTrue(
            app.buttons["workspace.work_time.finish"].waitForExistence(timeout: 12)
                || app.staticTexts["작업 시간을 기록 중이에요."].waitForExistence(timeout: 12),
            "작업공간 진입 후 작업 시간이 기록 중이어야 합니다."
        )
        return self
    }

    @discardableResult
    func finishCurrentWorkSessionAfterMinimumDuration() -> WorkspacePage {
        Thread.sleep(forTimeInterval: 11)
        tap(app.buttons["workspace.work_time.finish"].firstMatch)
        waitUntilWorkSessionsButtonIsEnabled()
        return self
    }

    @discardableResult
    func expectWorkSessionRecorded() -> WorkspacePage {
        let sessionsButton = app.buttons["workspace.work_time.sessions"].firstMatch
        waitUntilWorkSessionsButtonIsEnabled()
        tap(sessionsButton)
        expectText("세션 내역")
        return self
    }

    private func waitUntilWorkSessionsButtonIsEnabled(
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons["workspace.work_time.sessions"].firstMatch
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if button.exists && button.isEnabled {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("작업 세션 내역 버튼이 활성화되어야 합니다.", file: file, line: line)
    }

    private func waitForStaticText(_ text: String, timeout: TimeInterval = 12) -> Bool {
        let element = app.staticTexts[text].firstMatch
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists {
                return true
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return false
    }
}
