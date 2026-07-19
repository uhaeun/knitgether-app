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
        replaceGaugeText("tool.gauge.sample_width", text: sampleWidth)
        replaceGaugeText("tool.gauge.sample_height", text: sampleHeight)
        replaceGaugeText("tool.gauge.sample_stitches", text: sampleStitches)
        replaceGaugeText("tool.gauge.sample_rows", text: sampleRows)
        replaceGaugeText("tool.gauge.target_width", text: targetWidth)
        replaceGaugeText("tool.gauge.target_height", text: targetHeight)
        dismissKeyboard()
        tap(materializedElement("tool.gauge.save_before"))
    }

    func expectBeforeWashGaugeSaved() {
        expectText("세탁 전 게이지를 저장했어요.")
    }

    func openMeasureHub() -> GaugeCalculatorPage {
        tap(materializedElement("tool.gauge.measure_hub"))
        XCTAssertTrue(
            app.navigationBars["게이지 측정"].waitForExistence(timeout: 12),
            "게이지 측정 화면이 보여야 합니다."
        )
        return self
    }

    func openGaugeTargetList() -> GaugeCalculatorPage {
        tap(materializedElement("tool.gauge.target.list"))
        XCTAssertTrue(
            app.navigationBars["목표 게이지"].waitForExistence(timeout: 12),
            "목표 게이지 목록 화면이 보여야 합니다."
        )
        return self
    }

    @discardableResult
    func addGaugeTarget(
        name: String,
        needle: String,
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) -> GaugeCalculatorPage {
        tap(app.buttons["tool.gauge.target.add"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["목표 게이지 추가"].waitForExistence(timeout: 12),
            "목표 게이지 추가 화면이 보여야 합니다."
        )
        fillGaugeTargetForm(
            name: name,
            needle: needle,
            width: width,
            height: height,
            stitches: stitches,
            rows: rows
        )
        tap(materializedElement("tool.gauge.target.save"))
        XCTAssertTrue(
            app.staticTexts[name].waitForExistence(timeout: 12),
            "추가한 목표 게이지가 목록에 보여야 합니다: \(name)"
        )
        return self
    }

    @discardableResult
    func expectGaugeTargetVisible(named name: String) -> GaugeCalculatorPage {
        XCTAssertTrue(
            app.staticTexts[name].waitForExistence(timeout: 12),
            "목표 게이지가 보여야 합니다: \(name)"
        )
        return self
    }

    @discardableResult
    func expectGaugeTargetNotVisible(named name: String) -> GaugeCalculatorPage {
        XCTAssertFalse(
            app.staticTexts[name].waitForExistence(timeout: 5),
            "목표 게이지가 보이면 안 됩니다: \(name)"
        )
        return self
    }

    func openGaugeTarget(named name: String) -> GaugeCalculatorPage {
        tap(gaugeTargetElement(named: name))
        XCTAssertTrue(
            app.navigationBars[name].waitForExistence(timeout: 12)
                || app.staticTexts[name].waitForExistence(timeout: 12),
            "목표 게이지 상세 화면이 보여야 합니다: \(name)"
        )
        return self
    }

    @discardableResult
    func editGaugeTarget(
        name: String,
        needle: String,
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) -> GaugeCalculatorPage {
        tap(app.buttons["tool.gauge.target.edit"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["목표 게이지 편집"].waitForExistence(timeout: 12),
            "목표 게이지 편집 화면이 보여야 합니다."
        )
        fillGaugeTargetForm(
            name: name,
            needle: needle,
            width: width,
            height: height,
            stitches: stitches,
            rows: rows
        )
        tap(materializedElement("tool.gauge.target.save"))
        return self
    }

    @discardableResult
    func expectGaugeTargetDetail(named name: String) -> GaugeCalculatorPage {
        XCTAssertTrue(
            app.navigationBars[name].waitForExistence(timeout: 12)
                || app.staticTexts[name].waitForExistence(timeout: 12),
            "목표 게이지 상세가 수정값으로 보여야 합니다: \(name)"
        )
        return self
    }

    func returnToGaugeTargetList() -> GaugeCalculatorPage {
        tap(app.navigationBars.buttons.element(boundBy: 0))
        XCTAssertTrue(
            app.navigationBars["목표 게이지"].waitForExistence(timeout: 12),
            "목표 게이지 목록으로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func deleteGaugeTarget(named name: String) -> GaugeCalculatorPage {
        let row = gaugeTargetElement(named: name)
        row.swipeLeft()
        tap(app.buttons["삭제"].firstMatch)

        let alert = app.alerts["목표 게이지를 삭제할까요?"].firstMatch
        XCTAssertTrue(
            alert.waitForExistence(timeout: 12),
            "목표 게이지 삭제 확인 alert가 보여야 합니다."
        )
        tap(alert.buttons["삭제"].firstMatch)
        return self
    }

    private func fillGaugeTargetForm(
        name: String,
        needle: String,
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) {
        replaceGaugeText("tool.gauge.target.form.name", text: name)
        replaceGaugeText("tool.gauge.target.form.needle", text: needle)
        dismissKeyboard()

        replaceGaugeText("tool.gauge.target.form.width", text: width)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.target.form.height", text: height)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.target.form.stitches", text: stitches)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.target.form.rows", text: rows)
        dismissKeyboard()
    }

    private func replaceGaugeText(_ identifier: String, text: String) {
        let element = materializedInputElement(identifier)
        tap(element)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        if let currentValue = element.value as? String, !currentValue.isEmpty {
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        }

        element.typeText(text)
    }

    private func materializedInputElement(
        _ identifier: String,
        timeout: TimeInterval = 12
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let textField = app.textFields[identifier].firstMatch
            if textField.exists {
                return textField
            }

            let secureField = app.secureTextFields[identifier].firstMatch
            if secureField.exists {
                return secureField
            }

            let textView = app.textViews[identifier].firstMatch
            if textView.exists {
                return textView
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return app.textFields[identifier].firstMatch
    }

    private func materializedElement(
        _ identifier: String,
        timeout: TimeInterval = 12
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let element = anyElement(identifier)
            if element.exists {
                return element
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return anyElement(identifier)
    }

    private func gaugeTargetElement(named name: String) -> XCUIElement {
        let rowPrefix = "tool.gauge.target.row."
        let rows = app.descendants(matching: .any).allElementsBoundByIndex.filter { element in
            element.identifier.hasPrefix(rowPrefix)
        }

        if let row = rows.first(where: { row in
            row.label.contains(name)
                || row.descendants(matching: .staticText)[name].exists
        }) {
            return row
        }

        return app.staticTexts[name].firstMatch
    }
}
