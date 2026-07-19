//
//  ProjectFormPage.swift
//  KnitGetherUITests
//

import XCTest

struct ProjectFormPage: UITestPage {
    let app: XCUIApplication

    func saveProject(named projectName: String) -> MyKnittingPage {
        enterText("project.form.name", text: projectName)
        dismissKeyboard()
        tap(app.buttons["project.save"].firstMatch)
        return MyKnittingPage(app: app)
    }

    @discardableResult
    func renameProject(to projectName: String) -> ProjectFormPage {
        replaceText("project.form.name", text: projectName)
        dismissKeyboard()
        tap(app.buttons["project.save"].firstMatch)
        return self
    }

    @discardableResult
    func expectProjectUpdated(named projectName: String) -> WorkspacePage {
        XCTAssertTrue(
            app.navigationBars["작업 공간"].waitForExistence(timeout: 12)
                || app.staticTexts[projectName].waitForExistence(timeout: 12),
            "프로젝트 수정 후 작업공간으로 돌아와야 합니다: \(projectName)"
        )
        return WorkspacePage(app: app)
    }

    func deleteProject() -> MyKnittingPage {
        tapDeleteButton()
        let alert = app.alerts["프로젝트를 삭제할까요?"].firstMatch
        XCTAssertTrue(
            alert.waitForExistence(timeout: 12),
            "프로젝트 삭제 확인 alert가 보여야 합니다."
        )
        tap(alert.buttons["삭제"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["나의 뜨개"].waitForExistence(timeout: 12)
                || app.tabBars.buttons["내 뜨개"].waitForExistence(timeout: 12),
            "프로젝트 삭제 후 내 뜨개 목록으로 돌아와야 합니다."
        )
        return MyKnittingPage(app: app)
    }

    private func tapDeleteButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<6 {
            if let button = app.buttons.matching(identifier: "project.delete")
                .allElementsBoundByIndex
                .first(where: \.isHittable) {
                tap(button, file: file, line: line)
                return
            }

            app.swipeUp()
        }

        XCTFail("프로젝트 삭제 버튼을 누를 수 있어야 합니다.", file: file, line: line)
    }
}
