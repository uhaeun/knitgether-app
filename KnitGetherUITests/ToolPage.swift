//
//  ToolPage.swift
//  KnitGetherUITests
//

import XCTest

struct ToolPage: UITestPage {
    let app: XCUIApplication

    func openGaugeCalculator() -> GaugeCalculatorPage {
        tap(app.buttons["tool.gauge_calculator"].firstMatch)
        return GaugeCalculatorPage(app: app)
    }

    func openDictionary() -> DictionaryPage {
        tap(app.buttons["tool.dictionary"].firstMatch)
        return DictionaryPage(app: app).expectVisible()
    }
}
