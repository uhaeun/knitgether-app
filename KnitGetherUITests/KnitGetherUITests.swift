//
//  KnitGetherUITests.swift
//  KnitGetherUITests
//
//  Created by yu haeun on 6/2/26.
//

import XCTest

final class KnitGetherUITests: KnitGetherUITestCase {

    @MainActor
    func testExample() throws {
        launchDefault()
    }

    @MainActor
    func testCoreUserFlowRegistersAndSavesCommonRecords() throws {
        let uniqueSuffix = Int(Date().timeIntervalSince1970)
        let email = "ui-flow-\(uniqueSuffix)@example.com"
        let projectName = "UI Flow Project \(uniqueSuffix)"

        let onboarding = launchForCoreFlow()
        let auth = onboarding.goToAuth().signOutIfNeeded()
        let signedInAuth = auth.register(
            email: email,
            password: "password-1234",
            displayName: "UI Flow Tester"
        )
        signedInAuth.expectRegistrationCompleted()

        let mainTabs = signedInAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .openSkillTest()
            .markFirstSkillKnownAndSave()
            .finishOnboarding()

        let myKnitting = mainTabs.openMyKnitting()
        myKnitting.openAddProject()
            .saveProject(named: projectName)
            .expectProjectSaved(named: projectName)

        let gaugeCalculator = mainTabs
            .openTools()
            .openGaugeCalculator()
        gaugeCalculator.saveBeforeWashGauge(
            sampleWidth: "10",
            sampleHeight: "10",
            sampleStitches: "22",
            sampleRows: "30",
            targetWidth: "40",
            targetHeight: "50"
        )
        gaugeCalculator.expectBeforeWashGaugeSaved()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
