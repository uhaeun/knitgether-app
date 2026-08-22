//
//  DEF-15_RegressionTests.swift
//  KnitGetherQAUITests
//
//  Created by yu haeun on 8/12/26.
//

import XCTest

final class DEF_15_RegressionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testDEF15() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-knitgether.onboardingCompleted", "YES"]
        app.launchEnvironment["KNITGETHER_API_BASE_URL"] = ""
        app.launch()
 
        
        let myKnitting = MyKnittingPage(app: app)
        myKnitting.open()
        let projectName = "DEF15-\(Int(Date().timeIntervalSince1970))"
        let workspace = myKnitting.createProject(named: projectName)

        // Given: 카운터가 0("시작 전") 상태
        let counter = workspace.openCounterSheet()
        counter.expectValue("시작 전")
        counter.close()
        
        // When: 카운터 바의 감소 버튼 탭 (DEF-15 결함 지점)
        workspace.tapDecrement()
        
        // Then: 여전히 0("시작 전")
        workspace.openCounterSheet().expectValue("시작 전")
        
    }
}
