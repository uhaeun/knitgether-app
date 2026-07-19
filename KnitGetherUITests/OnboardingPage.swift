//
//  OnboardingPage.swift
//  KnitGetherUITests
//

import XCTest

struct OnboardingPage: UITestPage {
    let app: XCUIApplication

    func goToAuth() -> AuthPage {
        tap(app.buttons["다음"].firstMatch)
        tap(app.buttons["onboarding.login"].firstMatch)
        return AuthPage(app: app)
    }

    func advanceToSkillTestStep() -> OnboardingPage {
        tapNext()
        tapNext()
        tapNext()
        return self
    }

    func openSkillTest() -> SkillTestPage {
        tap(app.buttons["스킬 테스트 시작"].firstMatch)
        return SkillTestPage(app: app)
    }

    func finishOnboarding() -> MainTabBarPage {
        tapNext()
        tap(app.buttons["시작"].firstMatch)

        let mainTabs = MainTabBarPage(app: app)
        mainTabs.expectVisible()
        return mainTabs
    }

    private func tapNext() {
        tap(app.buttons["다음"].firstMatch)
    }
}
