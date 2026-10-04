import XCTest

struct MyKnittingPage {
    let app: XCUIApplication

    func open() {
        let myKnittingTab = app.tabBars.buttons["내 뜨개"]
        XCTAssertTrue(myKnittingTab.waitForExistence(timeout: 5))
        myKnittingTab.tap()
    }

    func createProject(named name: String) -> WorkspacePage {
        let addButton = app.buttons["project.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["project.form.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)

        let saveButton = app.buttons["project.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let projectRow = app.staticTexts[name]
        // A favorite or an existing record may appear above the new project.
        // Scroll the list to the actual saved row before opening it.
        for _ in 0..<5 {
            if projectRow.exists && projectRow.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(projectRow.waitForExistence(timeout: 5))
        XCTAssertTrue(projectRow.isHittable)
        projectRow.tap()

        return WorkspacePage(app: app)
    }
}
