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

    func expectProjectSaved(named projectName: String) {
        XCTAssertTrue(
            app.staticTexts["프로젝트를 추가했어요."].waitForExistence(timeout: 12)
                || app.staticTexts[projectName].waitForExistence(timeout: 12),
            "프로젝트 저장 후 성공 메시지 또는 프로젝트 이름이 보여야 합니다."
        )
    }
}
