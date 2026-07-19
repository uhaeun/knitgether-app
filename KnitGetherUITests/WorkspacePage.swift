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
        _ = waitUntilWorkSessionsButtonIsReady()
        return self
    }

    @discardableResult
    func openWorkSessions() -> WorkspacePage {
        let sessionsButton = waitUntilWorkSessionsButtonIsReady()
        sessionsButton.tap()

        if !app.navigationBars["세션 내역"].waitForExistence(timeout: 4) {
            sessionsButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        XCTAssertTrue(
            app.navigationBars["세션 내역"].waitForExistence(timeout: 12),
            "세션 내역 화면으로 이동해야 합니다. visibleElements=\(visibleElementSummary())"
        )
        return self
    }

    @discardableResult
    func expectWorkSessionRecorded() -> WorkspacePage {
        openWorkSessions()
    }

    @discardableResult
    func deleteFirstWorkSession() -> WorkspacePage {
        let sessionRow = firstWorkSessionRow()
        XCTAssertNotNil(
            sessionRow,
            "삭제할 작업 세션 행이 보여야 합니다. visibleElements=\(visibleElementSummary())"
        )
        sessionRow?.press(forDuration: 1.0)

        let deleteButton = app.buttons["삭제"].firstMatch
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 12),
            "작업 세션 context menu의 삭제 버튼이 보여야 합니다."
        )
        tap(deleteButton)

        let alert = app.alerts["세션을 삭제할까요?"].firstMatch
        XCTAssertTrue(
            alert.waitForExistence(timeout: 12),
            "작업 세션 삭제 확인 alert가 보여야 합니다."
        )
        tap(alert.buttons["삭제"].firstMatch)
        return self
    }

    @discardableResult
    func expectNoWorkSessions() -> WorkspacePage {
        XCTAssertTrue(
            app.staticTexts["세션 기록이 없어요"].waitForExistence(timeout: 12),
            "세션 삭제 후 빈 세션 상태가 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func expectWorkSessionsUnavailable() -> WorkspacePage {
        let sessionsButton = app.buttons["workspace.work_time.sessions"].firstMatch
        XCTAssertTrue(
            sessionsButton.waitForExistence(timeout: 12),
            "작업 세션 내역 버튼이 보여야 합니다."
        )
        XCTAssertFalse(
            sessionsButton.isEnabled,
            "저장된 작업 세션이 없으면 세션 내역 버튼이 비활성화되어야 합니다."
        )
        return self
    }

    private func waitUntilWorkSessionsButtonIsReady(
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = app.buttons["workspace.work_time.sessions"].firstMatch
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if button.exists
                && button.isEnabled
                && button.isHittable
                && (button.label.contains("1회") || app.staticTexts["1회"].exists) {
                return button
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("작업 세션 내역 버튼이 활성화되어야 합니다.", file: file, line: line)
        return button
    }

    private func firstWorkSessionRow(timeout: TimeInterval = 12) -> XCUIElement? {
        let prefix = "workspace.work_session.row."
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let row = app.descendants(matching: .any).allElementsBoundByIndex.first(where: {
                $0.identifier.hasPrefix(prefix) && $0.exists
            }) {
                return row
            }

            if let cell = app.cells.allElementsBoundByIndex.last(where: { $0.exists }) {
                return cell
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return nil
    }

    private func visibleElementSummary(limit: Int = 80) -> String {
        app.descendants(matching: .any).allElementsBoundByIndex
            .prefix(limit)
            .map { element in
                "type=\(element.elementType.rawValue), id=\(element.identifier), label=\(element.label)"
            }
            .joined(separator: " | ")
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
