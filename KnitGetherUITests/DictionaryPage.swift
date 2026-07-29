//
//  DictionaryPage.swift
//  KnitGetherUITests
//

import XCTest

struct DictionaryPage: UITestPage {
    let app: XCUIApplication

    @discardableResult
    func expectVisible() -> DictionaryPage {
        XCTAssertTrue(
            app.navigationBars["뜨개 사전"].waitForExistence(timeout: 12),
            "뜨개 사전 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func expectTermVisible(_ term: String) -> DictionaryPage {
        let element = app.staticTexts[term]
        // 시스템 사전(§23 seed)이 모든 사용자 목록에 병합되면서 목록이 길어져,
        // 대상 용어가 초기 화면 밖에 있을 수 있다. SwiftUI 지연 리스트는 화면 밖 행을
        // 접근성 트리에 올리지 않으므로, 나타날 때까지 아래로 스크롤하며 찾는다.
        if !element.waitForExistence(timeout: 6) {
            for _ in 0..<12 where !element.exists {
                app.swipeUp()
            }
        }
        XCTAssertTrue(
            element.exists,
            "사전 목록에 용어가 보여야 합니다: \(term)"
        )
        return self
    }

    @discardableResult
    func expectTermNotVisible(_ term: String) -> DictionaryPage {
        XCTAssertFalse(
            app.staticTexts[term].waitForExistence(timeout: 5),
            "검색/필터로 걸러진 용어가 보이면 안 됩니다: \(term)"
        )
        return self
    }

    func openTerm(_ term: String) -> DictionaryPage {
        let row = app.buttons["tool.dictionary.term.\(term)"].firstMatch
        if row.waitForExistence(timeout: 4) {
            tap(row)
        } else {
            tap(app.staticTexts[term].firstMatch)
        }
        XCTAssertTrue(
            app.navigationBars["사전 상세"].waitForExistence(timeout: 12),
            "사전 상세 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func expectDetailShows(term: String, description: String) -> DictionaryPage {
        XCTAssertTrue(
            app.staticTexts[term].waitForExistence(timeout: 12),
            "상세에 용어가 보여야 합니다: \(term)"
        )
        XCTAssertTrue(
            app.staticTexts[description].waitForExistence(timeout: 12),
            "상세에 뜻이 보여야 합니다: \(description)"
        )
        return self
    }

    func returnToList() -> DictionaryPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        return expectVisible()
    }

    @discardableResult
    func search(_ text: String) -> DictionaryPage {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 12), "검색창이 보여야 합니다.")
        tap(field)
        field.typeText(text)
        return self
    }
}
