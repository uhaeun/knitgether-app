//
//  MyKnittingPage.swift
//  KnitGetherUITests
//

import XCTest

struct MyKnittingPage: UITestPage {
    let app: XCUIApplication

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
}
