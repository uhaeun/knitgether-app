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
    func testProjectPersistsAfterAppRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let email = "ui-relaunch-\(uniqueSuffix)@example.com"
        let projectName = "Relaunch Project \(uniqueSuffix)"

        let onboarding = launchForCoreFlow()
        let auth = onboarding.goToAuth().signOutIfNeeded()
        let signedInAuth = auth.register(
            email: email,
            password: "password-1234",
            displayName: "UI Relaunch Tester"
        )
        signedInAuth.expectRegistrationCompleted()

        let mainTabs = signedInAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .finishOnboarding()

        mainTabs.openMyKnitting()
            .openAddProject()
            .saveProject(named: projectName)
            .expectProjectSaved(named: projectName)

        relaunchForExistingSession()
            .openMyKnitting()
            .expectProjectVisible(named: projectName)
    }

    @MainActor
    func testWorkspaceRowCounterPersistsAfterAppRelaunch() throws {
        let projectName = registerAndCreateProject(prefix: "Row Counter")

        MainTabBarPage(app: app)
            .openMyKnitting()
            .openProject(named: projectName)
            .advanceRow()
            .expectCurrentRow(1)

        relaunchForExistingSession()
            .openMyKnitting()
            .openProject(named: projectName)
            .expectCurrentRow(1)
    }

    @MainActor
    func testWorkspaceWorkSessionCanBeRecorded() throws {
        let projectName = registerAndCreateProject(prefix: "Work Session")

        MainTabBarPage(app: app)
            .openMyKnitting()
            .openProject(named: projectName)
            .expectWorkTimerRunning()
            .finishCurrentWorkSessionAfterMinimumDuration()
            .expectWorkSessionRecorded()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func registerAndCreateProject(prefix: String) -> String {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let email = "ui-workspace-\(uniqueSuffix)@example.com"
        let projectName = "\(prefix) \(uniqueSuffix)"

        let onboarding = launchForCoreFlow()
        let auth = onboarding.goToAuth().signOutIfNeeded()
        let signedInAuth = auth.register(
            email: email,
            password: "password-1234",
            displayName: "UI Workspace Tester"
        )
        signedInAuth.expectRegistrationCompleted()

        let mainTabs = signedInAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .finishOnboarding()

        mainTabs.openMyKnitting()
            .openAddProject()
            .saveProject(named: projectName)
            .expectProjectSaved(named: projectName)

        return projectName
    }
}
