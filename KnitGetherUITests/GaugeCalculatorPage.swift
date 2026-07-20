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

    @discardableResult
    func addGaugeSwatch(
        needleSize: String,
        yarnName: String,
        stitchPattern: String = "",
        notes: String = ""
    ) -> GaugeCalculatorPage {
        tap(materializedElement("tool.gauge.swatch.add"))
        XCTAssertTrue(
            app.navigationBars["스와치 추가"].waitForExistence(timeout: 12),
            "스와치 추가 화면이 보여야 합니다."
        )
        fillGaugeSwatchForm(
            needleSize: needleSize,
            yarnName: yarnName,
            stitchPattern: stitchPattern,
            notes: notes
        )
        tap(materializedElement("tool.gauge.swatch.save"))
        XCTAssertTrue(
            app.staticTexts[needleSize].waitForExistence(timeout: 12),
            "추가한 스와치가 목표 상세에 보여야 합니다: \(needleSize)"
        )
        return self
    }

    @discardableResult
    func expectGaugeSwatchVisible(
        needleSize: String,
        yarnName: String
    ) -> GaugeCalculatorPage {
        XCTAssertTrue(
            app.staticTexts[needleSize].waitForExistence(timeout: 12),
            "스와치 바늘 호수가 보여야 합니다: \(needleSize)"
        )
        XCTAssertTrue(
            app.staticTexts[yarnName].waitForExistence(timeout: 12)
                || hasVisibleText(containing: yarnName),
            "스와치 실 이름이 보여야 합니다: \(yarnName)"
        )
        return self
    }

    @discardableResult
    func openGaugeSwatch(needleSize: String) -> GaugeCalculatorPage {
        tap(gaugeSwatchElement(needleSize: needleSize))
        XCTAssertTrue(
            app.navigationBars["스와치 상세"].waitForExistence(timeout: 12),
            "스와치 상세 화면이 보여야 합니다: \(needleSize)"
        )
        return self
    }

    @discardableResult
    func addManualMeasurement(
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) -> GaugeCalculatorPage {
        tap(app.buttons["측정 추가"].firstMatch)
        XCTAssertTrue(
            app.navigationBars["측정 방법"].waitForExistence(timeout: 12),
            "측정 방법 화면이 보여야 합니다."
        )
        tap(materializedElement("tool.gauge.measure.manual_method"))
        XCTAssertTrue(
            app.navigationBars["수동 측정"].waitForExistence(timeout: 12),
            "수동 측정 화면이 보여야 합니다."
        )
        fillManualMeasurementForm(
            width: width,
            height: height,
            stitches: stitches,
            rows: rows
        )
        tap(materializedElement("tool.gauge.measure.save"))
        if app.navigationBars["측정 방법"].waitForExistence(timeout: 12) {
            tap(app.navigationBars.buttons["스와치 상세"].firstMatch)
        }
        XCTAssertTrue(
            app.navigationBars["스와치 상세"].waitForExistence(timeout: 12),
            "측정 저장 후 스와치 상세로 돌아와야 합니다."
        )
        return self
    }

    @discardableResult
    func expectManualMeasurement(
        stitches: String,
        rows: String
    ) -> GaugeCalculatorPage {
        XCTAssertTrue(
            hasVisibleText(containing: "\(stitches)코"),
            "측정 코 수가 보여야 합니다: \(stitches)코"
        )
        XCTAssertTrue(
            hasVisibleText(containing: "\(rows)단"),
            "측정 단 수가 보여야 합니다: \(rows)단"
        )
        return self
    }

    @discardableResult
    func editFirstManualMeasurement(
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) -> GaugeCalculatorPage {
        tap(firstGaugeMeasurementElement())
        XCTAssertTrue(
            app.navigationBars["측정 수정"].waitForExistence(timeout: 12),
            "측정 수정 화면이 보여야 합니다."
        )
        fillManualMeasurementForm(
            width: width,
            height: height,
            stitches: stitches,
            rows: rows
        )
        tap(materializedElement("tool.gauge.measure.save"))
        XCTAssertTrue(
            app.navigationBars["스와치 상세"].waitForExistence(timeout: 12),
            "측정 수정 후 스와치 상세로 돌아와야 합니다."
        )
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

    private func fillGaugeSwatchForm(
        needleSize: String,
        yarnName: String,
        stitchPattern: String,
        notes: String
    ) {
        replaceGaugeText("tool.gauge.swatch.form.needle_size", text: needleSize)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.swatch.form.yarn_name", text: yarnName)
        dismissKeyboard()
        if !stitchPattern.isEmpty {
            replaceGaugeText("tool.gauge.swatch.form.pattern", text: stitchPattern)
            dismissKeyboard()
        }
        if !notes.isEmpty {
            replaceGaugeText("tool.gauge.swatch.form.notes", text: notes)
            dismissKeyboard()
        }
    }

    private func fillManualMeasurementForm(
        width: String,
        height: String,
        stitches: String,
        rows: String
    ) {
        replaceGaugeText("tool.gauge.measure.width", text: width)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.measure.height", text: height)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.measure.stitches", text: stitches)
        dismissKeyboard()
        replaceGaugeText("tool.gauge.measure.rows", text: rows)
        dismissKeyboard()
    }

    private func replaceGaugeText(_ identifier: String, text: String) {
        let element = materializedInputElement(identifier)
        tap(element)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        if let currentValue = element.value as? String,
           shouldClearTextValue(currentValue) {
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
            let query = app.descendants(matching: .any).matching(identifier: identifier)
            let matches = query.allElementsBoundByIndex
            if let inputIndex = matches.firstIndex(where: {
                $0.elementType == .textField
                    || $0.elementType == .secureTextField
                    || $0.elementType == .textView
            }) {
                return query.element(boundBy: inputIndex)
            }
            if let hittableIndex = matches.firstIndex(where: \.isHittable) {
                return query.element(boundBy: hittableIndex)
            }

            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return anyElement(identifier)
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

    private func gaugeSwatchElement(needleSize: String) -> XCUIElement {
        let buttons = app.buttons.allElementsBoundByIndex
        if let button = buttons.first(where: { button in
            button.label.contains(needleSize)
                && button.label.contains("측정")
        }) {
            return button
        }

        let rowPrefix = "tool.gauge.swatch.row."
        let rows = app.descendants(matching: .any).allElementsBoundByIndex.filter { element in
            element.identifier.hasPrefix(rowPrefix)
        }

        if let row = rows.first(where: { row in
            row.label.contains(needleSize)
                || row.descendants(matching: .staticText)[needleSize].exists
        }) {
            return row
        }

        return app.staticTexts[needleSize].firstMatch
    }

    private func firstGaugeMeasurementElement() -> XCUIElement {
        let rowPrefix = "tool.gauge.measure.row."
        let rows = app.descendants(matching: .any).allElementsBoundByIndex.filter { element in
            element.identifier.hasPrefix(rowPrefix)
        }

        if let row = rows.first {
            return row
        }

        return app.staticTexts["세탁 전 · 수동 측정"].firstMatch
    }

    private func hasVisibleText(containing value: String) -> Bool {
        app.staticTexts.allElementsBoundByIndex.contains {
            $0.label.contains(value)
        }
    }

    private func shouldClearTextValue(_ value: String) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return false
        }

        return !trimmedValue.hasPrefix("예:")
    }
}
