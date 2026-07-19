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
}
