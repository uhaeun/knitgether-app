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

    func advanceRow() -> WorkspacePage {
        tap(app.buttons["workspace.counter.next"].firstMatch)
        return self
    }

    func expectCurrentRow(_ row: Int) -> WorkspacePage {
        XCTAssertTrue(
            app.staticTexts["현재 \(row)단"].waitForExistence(timeout: 12)
                || app.staticTexts["\(row)단 · 총 단수 미설정"].waitForExistence(timeout: 12),
            "현재 단수가 \(row)단으로 표시되어야 합니다."
        )
        return self
    }

    func expectWorkTimerRunning() -> WorkspacePage {
        XCTAssertTrue(
            app.buttons["workspace.work_time.finish"].waitForExistence(timeout: 12)
                || app.staticTexts["작업 시간을 기록 중이에요."].waitForExistence(timeout: 12),
            "작업공간 진입 후 작업 시간이 기록 중이어야 합니다."
        )
        return self
    }

    func finishCurrentWorkSessionAfterMinimumDuration() -> WorkspacePage {
        Thread.sleep(forTimeInterval: 11)
        tap(app.buttons["workspace.work_time.finish"].firstMatch)
        waitUntilWorkSessionsButtonIsEnabled()
        return self
    }

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
}
