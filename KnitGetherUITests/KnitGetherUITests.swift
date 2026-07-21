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
    func testWorkspaceWorkSessionCanBeDeletedAndStaysDeletedAfterRelaunch() throws {
        let projectName = registerAndCreateProject(prefix: "Session Delete")

        MainTabBarPage(app: app)
            .openMyKnitting()
            .openProject(named: projectName)
            .expectWorkTimerRunning()
            .finishCurrentWorkSessionAfterMinimumDuration()
            .openWorkSessions()
            .deleteFirstWorkSession()
            .expectNoWorkSessions()

        relaunchForExistingSession()
            .openMyKnitting()
            .openProject(named: projectName)
            .expectWorkSessionsUnavailable()
    }

    @MainActor
    func testServerOffWithCachedProjectShowsCachedProject() throws {
        let cacheDirectory = try makeLocalCacheDirectory(prefix: "server-off-cache")
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let projectName = registerAndCreateProject(
            prefix: "Cached Offline",
            localCacheDirectory: cacheDirectory
        )

        relaunchForExistingSession(
            apiBaseURL: "http://127.0.0.1:1/api/v1",
            localCacheDirectory: cacheDirectory
        )
        .openMyKnitting()
        .expectProjectVisible(named: projectName)
    }

    @MainActor
    func testServerOffWithoutProjectCacheShowsOfflineNotice() throws {
        let sessionCacheDirectory = try makeLocalCacheDirectory(prefix: "server-off-session")
        let emptyCacheDirectory = try makeLocalCacheDirectory(prefix: "server-off-empty-cache")
        defer {
            try? FileManager.default.removeItem(at: sessionCacheDirectory)
            try? FileManager.default.removeItem(at: emptyCacheDirectory)
        }

        registerAndFinishOnboarding(localCacheDirectory: sessionCacheDirectory)

        relaunchForExistingSession(
            apiBaseURL: "http://127.0.0.1:1/api/v1",
            localCacheDirectory: emptyCacheDirectory
        )
        .openMyKnitting()
        .expectOfflineNotice()
    }

    @MainActor
    func testServerOffPendingProjectSyncsAfterServerRecovers() throws {
        let cacheDirectory = try makeLocalCacheDirectory(prefix: "pending-retry")
        let verificationCacheDirectory = try makeLocalCacheDirectory(prefix: "pending-retry-verify")
        defer {
            try? FileManager.default.removeItem(at: cacheDirectory)
            try? FileManager.default.removeItem(at: verificationCacheDirectory)
        }
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let projectName = "Pending Offline \(uniqueSuffix)"

        registerAndFinishOnboarding(localCacheDirectory: cacheDirectory)

        relaunchForExistingSession(
            apiBaseURL: "http://127.0.0.1:1/api/v1",
            localCacheDirectory: cacheDirectory
        )
        .openMyKnitting()
        .openAddProject()
        .saveProject(named: projectName)
        .expectProjectSaved(named: projectName)

        relaunchForExistingSession(localCacheDirectory: cacheDirectory)
            .openMyKnitting()
            .expectProjectVisible(named: projectName)

        relaunchForExistingSession(localCacheDirectory: verificationCacheDirectory)
            .openMyKnitting()
            .expectProjectVisible(named: projectName)
    }

    @MainActor
    func testAccountSwitchKeepsProjectCacheSeparatedByUser() throws {
        let cacheRootDirectory = try makeLocalCacheDirectory(prefix: "account-scope")
        defer { try? FileManager.default.removeItem(at: cacheRootDirectory) }
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let firstEmail = "ui-account-a-\(uniqueSuffix)@example.com"
        let secondEmail = "ui-account-b-\(uniqueSuffix)@example.com"
        let firstProjectName = "Account A Project \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding(
            email: firstEmail,
            displayName: "UI Account A",
            localCacheRootDirectory: cacheRootDirectory
        )

        mainTabs.openMyKnitting()
            .openAddProject()
            .saveProject(named: firstProjectName)
            .expectProjectSaved(named: firstProjectName)

        _ = mainTabs.openSettings()
            .openAccount()
            .signOutIfNeeded()

        if app.state != .notRunning {
            app.terminate()
        }
        let secondAuth = launchForCoreFlow(localCacheRootDirectory: cacheRootDirectory)
            .goToAuth()
            .signOutIfNeeded()
            .register(
                email: secondEmail,
                password: "password-1234",
                displayName: "UI Account B"
            )
        secondAuth.expectRegistrationCompleted(displayName: "UI Account B")

        let secondMainTabs = secondAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .finishOnboarding()

        secondMainTabs.openMyKnitting()
            .expectProjectNotVisible(named: firstProjectName)
    }

    @MainActor
    func testExistingAccountCanLogInAndReachMainTabs() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let email = "ui-login-\(uniqueSuffix)@example.com"
        let password = "password-1234"
        let displayName = "UI Login Tester"

        let initialMainTabs = registerAndFinishOnboarding(
            email: email,
            displayName: displayName
        )

        _ = initialMainTabs.openSettings()
            .openAccount()
            .signOutIfNeeded()

        if app.state != .notRunning {
            app.terminate()
        }

        let loggedInAuth = launchForCoreFlow()
            .goToAuth()
            .signOutIfNeeded()
            .login(email: email, password: password)

        loggedInAuth.expectLoginCompleted(displayName: displayName)

        loggedInAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .finishOnboarding()
            .openMyKnitting()
            .expectVisible()
    }

    @MainActor
    func testWrongPasswordLoginShowsErrorAndDoesNotPersistSession() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let email = "ui-login-fail-\(uniqueSuffix)@example.com"
        let displayName = "UI Login Failure Tester"

        let initialMainTabs = registerAndFinishOnboarding(
            email: email,
            displayName: displayName
        )

        _ = initialMainTabs.openSettings()
            .openAccount()
            .signOutIfNeeded()

        if app.state != .notRunning {
            app.terminate()
        }

        launchForCoreFlow()
            .goToAuth()
            .signOutIfNeeded()
            .login(email: email, password: "wrong-password")
            .expectInvalidCredentialsMessage()

        if app.state != .notRunning {
            app.terminate()
        }

        launchForCoreFlow()
            .goToAuth()
            .expectSignedOut()
    }

    @MainActor
    func testLogoutDoesNotShowProfileLoadError() throws {
        let mainTabs = registerAndFinishOnboarding()
        let settings = mainTabs.openSettings()

        settings.openAccount()
            .signOutIfNeeded()
            .returnToSettings()
            .openProfile()
            .expectProfileLoadErrorNotVisible()
    }

    @MainActor
    func testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalProjectName = "Editable Project \(uniqueSuffix)"
        let editedProjectName = "Edited Project \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openMyKnitting()
            .openAddProject()
            .saveProject(named: originalProjectName)
            .expectProjectSaved(named: originalProjectName)

        let workspace = mainTabs.openMyKnitting()
            .openProject(named: originalProjectName)

        workspace.openEditProject()
            .renameProject(to: editedProjectName)
            .expectProjectUpdated(named: editedProjectName)

        workspace.returnToMyKnitting()
            .expectProjectVisible(named: editedProjectName)
            .expectProjectNotVisible(named: originalProjectName)

        relaunchForExistingSession()
            .openMyKnitting()
            .expectProjectVisible(named: editedProjectName)
            .openProject(named: editedProjectName)
            .openEditProject()
            .deleteProject()
            .expectProjectNotVisible(named: editedProjectName)

        relaunchForExistingSession()
            .openMyKnitting()
            .expectProjectNotVisible(named: editedProjectName)
    }

    @MainActor
    func testWorkspaceRowInstructionCanBeSavedEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let projectName = registerAndCreateProject(prefix: "Row Instruction")
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalInstruction = "Knit across \(uniqueSuffix)"
        let editedInstruction = "Purl back \(uniqueSuffix)"

        MainTabBarPage(app: app)
            .openMyKnitting()
            .openProject(named: projectName)
            .addRowInstruction(row: 1, text: originalInstruction)
            .expectRowInstruction(text: originalInstruction)
            .editFirstRowInstruction(row: 1, text: editedInstruction)
            .expectRowInstruction(text: editedInstruction)
            .expectRowInstructionNotVisible(text: originalInstruction)

        relaunchForExistingSession()
            .openMyKnitting()
            .openProject(named: projectName)
            .expectRowInstruction(text: editedInstruction)
            .deleteFirstRowInstruction()
            .expectRowInstructionNotVisible(text: editedInstruction)

        relaunchForExistingSession()
            .openMyKnitting()
            .openProject(named: projectName)
            .expectRowInstructionNotVisible(text: editedInstruction)
    }

    @MainActor
    func testGaugeTargetCanBeEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalTargetName = "Gauge Target \(uniqueSuffix)"
        let editedTargetName = "Edited Gauge \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .addGaugeTarget(
                name: originalTargetName,
                needle: "4.0mm",
                width: "10",
                height: "10",
                stitches: "22",
                rows: "30"
            )
            .expectGaugeTargetVisible(named: originalTargetName)

        relaunchForExistingSession()
            .openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .expectGaugeTargetVisible(named: originalTargetName)
            .openGaugeTarget(named: originalTargetName)
            .editGaugeTarget(
                name: editedTargetName,
                needle: "4.5mm",
                width: "10",
                height: "10",
                stitches: "24",
                rows: "32"
            )
            .expectGaugeTargetDetail(named: editedTargetName)
            .returnToGaugeTargetList()
            .expectGaugeTargetVisible(named: editedTargetName)
            .expectGaugeTargetNotVisible(named: originalTargetName)

        relaunchForExistingSession()
            .openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .expectGaugeTargetVisible(named: editedTargetName)
            .deleteGaugeTarget(named: editedTargetName)
            .expectGaugeTargetNotVisible(named: editedTargetName)

        relaunchForExistingSession()
            .openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .expectGaugeTargetNotVisible(named: editedTargetName)
    }

    @MainActor
    func testGaugeSwatchAndManualMeasurementPersistAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let targetName = "Swatch Target \(uniqueSuffix)"
        let swatchNeedle = "5.0mm"
        let swatchYarn = "QA Yarn \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .addGaugeTarget(
                name: targetName,
                needle: "5.0mm",
                width: "10",
                height: "10",
                stitches: "22",
                rows: "30"
            )
            .openGaugeTarget(named: targetName)
            .addGaugeSwatch(
                needleSize: swatchNeedle,
                yarnName: swatchYarn
            )
            .expectGaugeSwatchVisible(needleSize: swatchNeedle, yarnName: swatchYarn)
            .openGaugeSwatch(needleSize: swatchNeedle)
            .addManualMeasurement(width: "10", height: "10", stitches: "22", rows: "30")
            .expectManualMeasurement(stitches: "22", rows: "30")
            .editFirstManualMeasurement(width: "10", height: "10", stitches: "24", rows: "32")
            .expectManualMeasurement(stitches: "24", rows: "32")

        relaunchForExistingSession()
            .openTools()
            .openGaugeCalculator()
            .openMeasureHub()
            .openGaugeTargetList()
            .openGaugeTarget(named: targetName)
            .expectGaugeSwatchVisible(needleSize: swatchNeedle, yarnName: swatchYarn)
            .openGaugeSwatch(needleSize: swatchNeedle)
            .expectManualMeasurement(stitches: "24", rows: "32")
    }

    @MainActor
    func testYarnLibraryCanBeAddedEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalName = "Yarn \(uniqueSuffix)"
        let editedName = "Edited Yarn \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openLibrary()
            .openYarnLibrary()
            .addYarn(name: originalName, brand: "QA Brand")
            .expectYarnVisible(named: originalName)
            .openYarn(named: originalName)
            .editYarn(name: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openYarnLibrary()
            .expectYarnVisible(named: editedName)
            .expectYarnNotVisible(named: originalName)
            .openYarn(named: editedName)
            .deleteYarn()
            .expectYarnNotVisible(named: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openYarnLibrary()
            .expectYarnNotVisible(named: editedName)
    }

    @MainActor
    func testNeedleLibraryCanBeAddedEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalName = "Needle \(uniqueSuffix)"
        let editedName = "Edited Needle \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openLibrary()
            .openNeedleLibrary()
            .addNeedle(name: originalName, size: "4.0mm")
            .expectNeedleVisible(named: originalName)
            .openNeedle(named: originalName)
            .editNeedle(name: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openNeedleLibrary()
            .expectNeedleVisible(named: editedName)
            .expectNeedleNotVisible(named: originalName)
            .openNeedle(named: editedName)
            .deleteNeedle()
            .expectNeedleNotVisible(named: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openNeedleLibrary()
            .expectNeedleNotVisible(named: editedName)
    }

    @MainActor
    func testToolLibraryCanBeAddedEditedDeletedAndStayDeletedAfterRelaunch() throws {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let originalName = "Tool \(uniqueSuffix)"
        let editedName = "Edited Tool \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding()

        mainTabs.openLibrary()
            .openToolLibrary()
            .addTool(name: originalName, type: "코마커")
            .expectToolVisible(named: originalName)
            .openTool(named: originalName)
            .editTool(name: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openToolLibrary()
            .expectToolVisible(named: editedName)
            .expectToolNotVisible(named: originalName)
            .openTool(named: editedName)
            .deleteTool()
            .expectToolNotVisible(named: editedName)

        relaunchForExistingSession()
            .openLibrary()
            .openToolLibrary()
            .expectToolNotVisible(named: editedName)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func registerAndCreateProject(
        prefix: String,
        localCacheDirectory: URL? = nil
    ) -> String {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let projectName = "\(prefix) \(uniqueSuffix)"

        let mainTabs = registerAndFinishOnboarding(localCacheDirectory: localCacheDirectory)

        mainTabs.openMyKnitting()
            .openAddProject()
            .saveProject(named: projectName)
            .expectProjectSaved(named: projectName)

        return projectName
    }

    @MainActor
    @discardableResult
    private func registerAndFinishOnboarding(
        email: String? = nil,
        displayName: String = "UI Workspace Tester",
        localCacheDirectory: URL? = nil,
        localCacheRootDirectory: URL? = nil
    ) -> MainTabBarPage {
        let uniqueSuffix = UUID().uuidString.prefix(8).lowercased()
        let email = email ?? "ui-offline-\(uniqueSuffix)@example.com"

        let onboarding = launchForCoreFlow(
            localCacheDirectory: localCacheDirectory,
            localCacheRootDirectory: localCacheRootDirectory
        )
        let auth = onboarding.goToAuth().signOutIfNeeded()
        let signedInAuth = auth.register(
            email: email,
            password: "password-1234",
            displayName: displayName
        )
        signedInAuth.expectRegistrationCompleted()

        let mainTabs = signedInAuth
            .returnToOnboarding()
            .advanceToSkillTestStep()
            .finishOnboarding()

        return mainTabs
    }
}
