//
//  GaugeCalculatorPage.swift
//  KnitGetherUITests
//

import XCTest

struct GaugeCalculatorPage: UITestPage {
    let app: XCUIApplication

    func saveBeforeWashGauge(
        sampleWidth: String,
        sampleHeight: String,
        sampleStitches: String,
        sampleRows: String,
        targetWidth: String,
        targetHeight: String
    ) {
        enterText("tool.gauge.sample_width", text: sampleWidth)
        enterText("tool.gauge.sample_height", text: sampleHeight)
        enterText("tool.gauge.sample_stitches", text: sampleStitches)
        enterText("tool.gauge.sample_rows", text: sampleRows)
        enterText("tool.gauge.target_width", text: targetWidth)
        enterText("tool.gauge.target_height", text: targetHeight)
        dismissKeyboard()
        tap(app.buttons["tool.gauge.save_before"].firstMatch)
    }

    func expectBeforeWashGaugeSaved() {
        expectText("세탁 전 게이지를 저장했어요.")
    }
}
