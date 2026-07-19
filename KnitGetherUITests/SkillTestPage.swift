//
//  SkillTestPage.swift
//  KnitGetherUITests
//

import XCTest

struct SkillTestPage: UITestPage {
    let app: XCUIApplication

    func markFirstSkillKnownAndSave() -> OnboardingPage {
        expectText("각 스킬을 얼마나 알고 있는지 선택해주세요.")
        tap(app.buttons["잘 알아요"].firstMatch)
        tap(app.buttons["나중에 하기"].firstMatch)
        tap(app.buttons["저장하고 나가기"].firstMatch)

        XCTAssertTrue(
            app.buttons["스킬 테스트 시작"].waitForExistence(timeout: 12),
            "스킬 테스트 저장 후 온보딩 스킬 테스트 단계로 돌아와야 합니다."
        )
        return OnboardingPage(app: app)
    }
}
