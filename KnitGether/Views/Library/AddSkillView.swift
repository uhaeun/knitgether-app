//
//  AddSkillView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: SkillFormData

    private let skill: Skill?
    let onSave: (SkillFormData) async -> Bool

    init(
        skill: Skill? = nil,
        onSave: @escaping (SkillFormData) async -> Bool
    ) {
        self.skill = skill
        self.onSave = onSave
        _formData = State(initialValue: skill.map(SkillFormData.init) ?? SkillFormData())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "기본 정보",
                        description: "사전, 행안내, 스킬 테스트에서 함께 쓰이는 이름이에요.",
                        systemImage: "graduationcap.fill",
                        tint: AppTheme.Color.lavender
                    ) {
                        AppFormTextFieldRow(
                            title: "스킬 이름",
                            placeholder: "예: 겉뜨기",
                            systemImage: "textformat",
                            text: $formData.name
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillNameField)

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "약어",
                            placeholder: "예: K",
                            systemImage: "textformat.abc",
                            text: $formData.abbreviation
                        )
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillAbbreviationField)

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "카테고리",
                            placeholder: "기초, 무늬, 마무리 등",
                            systemImage: "folder",
                            text: $formData.category
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillCategoryField)

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "난이도",
                            placeholder: "초급, 중급, 고급",
                            systemImage: "chart.bar",
                            text: $formData.difficulty
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillDifficultyField)
                    }

                    AppFormSection(
                        title: "설명",
                        description: "사용자가 도안을 보다가 확인할 설명입니다.",
                        systemImage: "text.quote",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextEditorRow(
                            title: "설명",
                            placeholder: "스킬 설명",
                            systemImage: "pencil.line",
                            text: $formData.description
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillDescriptionField)
                    }

                    AppFormSection(
                        title: "기본 흐름",
                        description: "한 줄에 한 단계씩 입력하면 학습 화면에 단계별로 표시돼요.",
                        systemImage: "list.number",
                        tint: AppTheme.Color.sage
                    ) {
                        AppFormTextFieldRow(
                            title: "단계",
                            placeholder: "한 줄에 한 단계씩 입력",
                            systemImage: "line.3.horizontal",
                            text: $formData.stepsText,
                            axis: .vertical,
                            minHeight: 110
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillStepsField)
                    }

                    AppFormSection(
                        title: "뜨개 애니메이션",
                        description: "스킬 학습 화면에서 연결할 애니메이션 정보를 남겨요.",
                        systemImage: "play.rectangle.fill",
                        tint: AppTheme.Color.amber
                    ) {
                        AppFormTextFieldRow(
                            title: "애니메이션 이름",
                            placeholder: "예: knit-basic",
                            systemImage: "play",
                            text: $formData.animationName
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillAnimationNameField)

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "애니메이션 종류",
                            placeholder: "gif, lottie, step 등",
                            systemImage: "rectangle.stack",
                            text: $formData.animationType
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.skillAnimationTypeField)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    isDisabled: !formData.canSave,
                    accessibilityIdentifier: AppAccessibilityID.Library.skillSaveButton
                ) {
                    Task {
                        let didSave = await onSave(formData)

                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
            .warmScreenBackground()
            .navigationTitle(skill == nil ? "스킬 추가" : "스킬 수정")
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
}

#Preview {
    AddSkillView { _ in true }
}
