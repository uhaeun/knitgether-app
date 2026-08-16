import XCTest

struct WorkspacePage {              // "작업 화면 담당자"라는 직원 정의
    let app: XCUIApplication        // 담당자가 아는 것: 조작할 앱
    
    func tapDecrement() {           // 담당자가 할 줄 아는 일: 감소 버튼 누르기
        let button = app.buttons["workspace.counter.previous"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }
    
    func openCounterSheet() -> CounterSheetPage {
        let toggle = app.buttons["workspace.counter.sheet_toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        return CounterSheetPage(app: app)
    }
}

