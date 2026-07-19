//
//  MyKnittingPage.swift
//  KnitGetherUITests
//

import XCTest

struct MyKnittingPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> MyKnittingPage {
        XCTAssertTrue(
            app.navigationBars["나의 뜨개"].waitForExistence(timeout: 12)
                || app.buttons["project.add"].waitForExistence(timeout: 12),
            "나의 뜨개 화면이 보여야 합니다."
        )
        return self
    }

    func openAddProject() -> ProjectFormPage {
        tap(app.buttons["project.add"].firstMatch)
        return ProjectFormPage(app: app)
    }

    func openProject(named projectName: String) -> WorkspacePage {
        tap(app.staticTexts[projectName].firstMatch)
        let workspace = WorkspacePage(app: app)
        workspace.expectVisible()
        return workspace
    }

    @discardableResult
    func expectProjectSaved(named projectName: String) -> MyKnittingPage {
        XCTAssertTrue(
            app.staticTexts["프로젝트를 추가했어요."].waitForExistence(timeout: 12)
                || app.staticTexts[projectName].waitForExistence(timeout: 12),
            "프로젝트 저장 후 성공 메시지 또는 프로젝트 이름이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func expectProjectVisible(named projectName: String) -> MyKnittingPage {
        XCTAssertTrue(
            app.staticTexts[projectName].waitForExistence(timeout: 12),
            "저장된 프로젝트가 목록에 보여야 합니다: \(projectName)"
        )
        return self
    }

    @discardableResult
    func expectProjectNotVisible(named projectName: String) -> MyKnittingPage {
        XCTAssertFalse(
            app.staticTexts[projectName].waitForExistence(timeout: 5),
            "다른 계정의 프로젝트가 목록에 보이면 안 됩니다: \(projectName)"
        )
        return self
    }

    @discardableResult
    func expectOfflineNotice() -> MyKnittingPage {
        XCTAssertTrue(
            app.staticTexts["서버에 연결하지 못했어요."].waitForExistence(timeout: 12),
            "캐시가 없는 오프라인 상태에서는 서버 연결 안내가 보여야 합니다."
        )
        XCTAssertTrue(
            app.staticTexts["프로젝트를 불러오지 못했어요."].waitForExistence(timeout: 12)
                || app.staticTexts["프로젝트 도안 목록을 불러오지 못했어요."].waitForExistence(timeout: 12)
                || app.staticTexts["프로젝트 재료를 불러오지 못했어요."].waitForExistence(timeout: 12),
            "오프라인 안내에는 실패한 데이터 영역이 보여야 합니다."
        )
        return self
    }
}
