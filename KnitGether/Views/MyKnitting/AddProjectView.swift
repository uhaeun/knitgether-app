//
//  AddProjectView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData = ProjectFormData()
    @State private var isSaving = false
    @State private var submissionErrorMessage: String?

    let availablePatterns: [PatternDocument]
    let availableYarns: [Yarn]
    let availableNeedles: [Needle]
    let onSave: (ProjectFormData) async -> Bool

    init(
        availablePatterns: [PatternDocument] = [],
        availableYarns: [Yarn] = [],
        availableNeedles: [Needle] = [],
        onSave: @escaping (ProjectFormData) async -> Bool
    ) {
        self.availablePatterns = availablePatterns
        self.availableYarns = availableYarns
        self.availableNeedles = availableNeedles
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ProjectFormView(
                        formData: $formData,
                        includesPatternName: true,
                        availablePatterns: availablePatterns,
                        availableYarns: availableYarns,
                        availableNeedles: availableNeedles
                    )

                    if let submissionErrorMessage {
                        AppFormErrorBanner(message: submissionErrorMessage)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, 96)
            }
            .warmScreenBackground()
            .navigationTitle("프로젝트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    isSaving = true
                    let didSave = await onSave(formData)
                    isSaving = false

                    if didSave {
                        submissionErrorMessage = nil
                        dismiss()
                    } else {
                        submissionErrorMessage = "프로젝트를 저장하지 못했어요. 입력값과 서버 연결을 확인해 주세요."
                    }
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("프로젝트 저장", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppTheme.Color.accent)
            .accessibilityIdentifier(AppAccessibilityID.Project.saveButton)
            .disabled(!formData.canSave || isSaving)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}

#Preview {
    AddProjectView { _ in true }
}
