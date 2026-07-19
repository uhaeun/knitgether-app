import SwiftUI

struct GaugeTargetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let existingTargetID: UUID?

    init(viewModel: GaugeMeasureViewModel, existingTargetID: UUID? = nil) {
        self.viewModel = viewModel
        self.existingTargetID = existingTargetID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "기본 정보",
                    description: "도안 기준 게이지나 목표 게이지를 등록해요.",
                    systemImage: "target",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormTextFieldRow(
                        title: "목표 이름",
                        placeholder: "예: 도안 게이지",
                        systemImage: "textformat",
                        text: $viewModel.targetForm.name
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetNameField)

                    AppFormDivider()

                    AppFormTextFieldRow(
                        title: "추천 바늘",
                        placeholder: "예: 4.0mm",
                        systemImage: "ruler",
                        text: $viewModel.targetForm.recommendedNeedle
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetNeedleField)

                    AppFormDivider()

                    AppFormToggleRow(
                        title: "세탁 후 게이지 기준",
                        subtitle: "세탁 후 값이 도안 기준이면 켜 주세요.",
                        systemImage: "drop.fill",
                        isOn: $viewModel.targetForm.gaugeAfterWash
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetAfterWashToggle)
                }

                AppFormSection(
                    title: "목표 게이지",
                    description: "측정 면적과 코/단 수를 입력하면 10cm 기준으로 비교해요.",
                    systemImage: "function",
                    tint: AppTheme.Color.sage
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $viewModel.targetForm.width)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetFormWidthField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $viewModel.targetForm.height)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetFormHeightField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "코 수", systemImage: "number", text: $viewModel.targetForm.stitches)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetFormStitchesField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "단 수", systemImage: "number", text: $viewModel.targetForm.rows)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetFormRowsField)
                }

                if let errorMessage = viewModel.errorMessage {
                    AppFormErrorBanner(message: errorMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: viewModel.isSaving,
                accessibilityIdentifier: AppAccessibilityID.Tool.gaugeTargetSaveButton
            ) {
                Task {
                    let didSave = await viewModel.saveTarget(existingID: existingTargetID)
                    if didSave {
                        dismiss()
                    }
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle(existingTargetID == nil ? "목표 게이지 추가" : "목표 게이지 편집")
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
