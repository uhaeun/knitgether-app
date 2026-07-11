import SwiftUI

struct GaugeSwatchListView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID

    @State private var isShowingAddSwatch = false
    @State private var swatchPendingEdit: GaugeSwatch?

    var body: some View {
        List {
            if let target = viewModel.target(id: targetID) {
                if target.swatches.isEmpty {
                    EmptyStateView(
                        title: "아직 스와치가 없어요.",
                        description: "바늘, 실, 무늬별로 스와치를 추가하고 세탁 전/후 측정값을 비교해 보세요.",
                        systemImage: "ruler"
                    )
                    .listRowStyle()
                }

                ForEach(target.swatches) { swatch in
                    NavigationLink {
                        SwatchDetailView(
                            viewModel: viewModel,
                            targetID: target.id,
                            swatchID: swatch.id
                        )
                    } label: {
                        GaugeSwatchSummaryRow(swatch: swatch)
                    }
                    .buttonStyle(.plain)
                    .listRowStyle()
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchRow(swatch.id))
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.prepareSwatchForm(for: swatch)
                            swatchPendingEdit = swatch
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("스와치")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.prepareSwatchForm(for: nil)
                    isShowingAddSwatch = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("스와치 추가")
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchAddButton)
            }
        }
        .sheet(isPresented: $isShowingAddSwatch) {
            NavigationStack {
                GaugeSwatchFormView(viewModel: viewModel, targetID: targetID)
            }
        }
        .sheet(item: $swatchPendingEdit) { swatch in
            NavigationStack {
                GaugeSwatchFormView(
                    viewModel: viewModel,
                    targetID: targetID,
                    existingSwatchID: swatch.id
                )
            }
        }
    }
}

struct GaugeSwatchFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let existingSwatchID: UUID?

    init(
        viewModel: GaugeMeasureViewModel,
        targetID: UUID,
        existingSwatchID: UUID? = nil
    ) {
        self.viewModel = viewModel
        self.targetID = targetID
        self.existingSwatchID = existingSwatchID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "바늘",
                    description: "같은 도안이어도 바늘별 게이지 차이를 기록해요.",
                    systemImage: "ruler.fill",
                    tint: AppTheme.Color.sage
                ) {
                    AppFormTextFieldRow(
                        title: "바늘 호수",
                        placeholder: "예: 4.0mm",
                        systemImage: "ruler",
                        text: $viewModel.swatchForm.needleSize
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchNeedleSizeField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "바늘 종류",
                        placeholder: "줄바늘, 대바늘 등",
                        systemImage: "tag",
                        text: $viewModel.swatchForm.needleType
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchNeedleTypeField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "바늘 소재",
                        placeholder: "금속, 나무 등",
                        systemImage: "sparkles",
                        text: $viewModel.swatchForm.needleMaterial
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchNeedleMaterialField)
                }

                AppFormSection(
                    title: "실",
                    description: "스와치에 사용한 실과 색상을 남겨요.",
                    systemImage: "circle.hexagongrid.fill",
                    tint: AppTheme.Color.rose
                ) {
                    AppFormTextFieldRow(
                        title: "실 이름",
                        placeholder: "실 이름",
                        systemImage: "textformat",
                        text: $viewModel.swatchForm.yarnName
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchYarnNameField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "브랜드",
                        placeholder: "브랜드",
                        systemImage: "tag",
                        text: $viewModel.swatchForm.yarnBrand
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchYarnBrandField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "색상",
                        placeholder: "색상 이름 또는 번호",
                        systemImage: "paintpalette",
                        text: $viewModel.swatchForm.yarnColor
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchYarnColorField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "로트",
                        placeholder: "로트 번호",
                        systemImage: "number",
                        text: $viewModel.swatchForm.yarnLot
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchYarnLotField)
                }

                AppFormSection(
                    title: "스와치",
                    description: "무늬와 메모를 남기면 세탁 전후 비교가 쉬워요.",
                    systemImage: "square.grid.3x3",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormTextFieldRow(
                        title: "무늬",
                        placeholder: "메리야스, 가터 등",
                        systemImage: "square.grid.3x3",
                        text: $viewModel.swatchForm.stitchPattern
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchPatternField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "메모",
                        placeholder: "메모",
                        systemImage: "pencil.line",
                        text: $viewModel.swatchForm.notes,
                        axis: .vertical,
                        minHeight: 90
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchNotesField)
                }

                if let errorMessage = viewModel.errorMessage {
                    AppFormErrorBanner(message: errorMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: viewModel.isSaving,
                accessibilityIdentifier: AppAccessibilityID.Tool.gaugeSwatchSaveButton
            ) {
                Task {
                    let didSave = await viewModel.saveSwatch(
                        targetID: targetID,
                        existingSwatchID: existingSwatchID
                    )
                    if didSave {
                        dismiss()
                    }
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle(existingSwatchID == nil ? "스와치 추가" : "스와치 편집")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }
        }
    }
}

struct SwatchDetailView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID

    @State private var isShowingEditSwatch = false
    @State private var measurementPendingEdit: GaugeMeasurement?

    var body: some View {
        Group {
            if let target = viewModel.target(id: targetID),
               let swatch = viewModel.swatch(id: swatchID, in: target) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppDetailHeaderView(
                            title: GaugeSwatchSummaryRow.title(for: swatch),
                            subtitle: swatch.yarnName,
                            systemImage: "ruler",
                            tint: AppTheme.Color.sage
                        )

                        detailSection(title: "스와치", systemImage: "ruler") {
                            GaugeSwatchSummaryRow(swatch: swatch)

                            Button {
                                viewModel.prepareSwatchForm(for: swatch)
                                isShowingEditSwatch = true
                            } label: {
                                Label("스와치 정보 편집", systemImage: "pencil")
                            }
                            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchEditButton)
                        }

                        detailSection(title: "측정", systemImage: "ruler") {
                            NavigationLink {
                                MeasurementMethodPickerView(
                                    viewModel: viewModel,
                                    targetID: target.id,
                                    swatchID: swatch.id
                                )
                            } label: {
                                Label("측정 추가", systemImage: "ruler")
                            }

                            if swatch.measurements.isEmpty {
                                Text("측정 로그가 없어요.")
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(swatch.measurements.sorted(by: { $0.updatedAt > $1.updatedAt })) { measurement in
                                Button {
                                    viewModel.prepareMeasurementForm(for: measurement)
                                    measurementPendingEdit = measurement
                                } label: {
                                    MeasurementRowView(measurement: measurement)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementRow(measurement.id))
                            }
                        }
                    }
                    .padding()
                }
                .warmScreenBackground()
                .navigationTitle("스와치 상세")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isShowingEditSwatch) {
                    NavigationStack {
                        GaugeSwatchFormView(
                            viewModel: viewModel,
                            targetID: target.id,
                            existingSwatchID: swatch.id
                        )
                    }
                }
                .sheet(item: $measurementPendingEdit) { measurement in
                    NavigationStack {
                        MeasurementEditView(
                            viewModel: viewModel,
                            targetID: target.id,
                            swatchID: swatch.id,
                            measurement: measurement
                        )
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "ruler")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("스와치를 찾지 못했어요.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .warmScreenBackground()
            }
        }
    }

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(title)

            AppSoftPanel {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
            }
        }
    }
}

struct GaugeSwatchSummaryRow: View {
    let swatch: GaugeSwatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: "ruler")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(swatch.measurements.count)개 측정")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let detail = [swatch.yarnName, swatch.stitchPattern, swatch.notes]
                .compactMap { value in
                    value?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")

            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let comparison {
                HStack {
                    Text("세탁 후 변화")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(signed(comparison.stitchDelta))코 · \(signed(comparison.rowDelta))단")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    static func title(for swatch: GaugeSwatch) -> String {
        if let needleSize = swatch.needleSize,
           !needleSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return needleSize
        }

        return "스와치"
    }

    private var title: String {
        Self.title(for: swatch)
    }

    private var comparison: GaugeSwatchWashComparison? {
        GaugeSwatchWashComparison(swatch: swatch)
    }

    private func signed(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(0...1))))"
    }
}

private struct GaugeSwatchWashComparison {
    let stitchDelta: Double
    let rowDelta: Double

    init?(swatch: GaugeSwatch) {
        guard
            let before = swatch.measurements
                .filter({ $0.washState == .before })
                .max(by: { $0.updatedAt < $1.updatedAt }),
            let after = swatch.measurements
                .filter({ $0.washState == .after })
                .max(by: { $0.updatedAt < $1.updatedAt })
        else {
            return nil
        }

        stitchDelta = after.finalStitches - before.finalStitches
        rowDelta = after.finalRows - before.finalRows
    }
}
