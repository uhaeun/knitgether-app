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
}
