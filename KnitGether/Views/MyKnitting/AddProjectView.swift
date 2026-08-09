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
    @State private var isShowingNewYarnForm = false
    @State private var isShowingNewNeedleForm = false
    @State private var isShowingNewToolForm = false

    let availablePatterns: [PatternDocument]
    let availableYarns: [Yarn]
    let availableNeedles: [Needle]
    let availableTools: [ToolItem]
    let onSave: (ProjectFormData) async -> Bool
    let onCreateYarn: ((YarnFormData) async -> Yarn?)?
    let onCreateNeedle: ((NeedleFormData) async -> Needle?)?
    let onCreateTool: ((ToolFormData) async -> ToolItem?)?

    init(
        availablePatterns: [PatternDocument] = [],
        availableYarns: [Yarn] = [],
        availableNeedles: [Needle] = [],
        availableTools: [ToolItem] = [],
        onSave: @escaping (ProjectFormData) async -> Bool,
        onCreateYarn: ((YarnFormData) async -> Yarn?)? = nil,
        onCreateNeedle: ((NeedleFormData) async -> Needle?)? = nil,
        onCreateTool: ((ToolFormData) async -> ToolItem?)? = nil
    ) {
        self.availablePatterns = availablePatterns
        self.availableYarns = availableYarns
        self.availableNeedles = availableNeedles
        self.availableTools = availableTools
        self.onSave = onSave
        self.onCreateYarn = onCreateYarn
        self.onCreateNeedle = onCreateNeedle
        self.onCreateTool = onCreateTool
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ProjectFormView(
                        formData: $formData,
                        includesPatternName: true,
                        includesToolSelection: true,
                        availablePatterns: availablePatterns,
                        availableYarns: availableYarns,
                        availableNeedles: availableNeedles,
                        availableTools: availableTools,
                        onRegisterYarn: onCreateYarn == nil ? nil : { isShowingNewYarnForm = true },
                        onRegisterNeedle: onCreateNeedle == nil ? nil : { isShowingNewNeedleForm = true },
                        onRegisterTool: onCreateTool == nil ? nil : { isShowingNewToolForm = true }
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
            .sheet(isPresented: $isShowingNewYarnForm) {
                YarnFormView(title: "새 실 등록") { yarnFormData in
                    guard let yarn = await onCreateYarn?(yarnFormData) else {
                        return false
                    }

                    formData.selectYarn(yarn)
                    return true
                }
            }
            .sheet(isPresented: $isShowingNewNeedleForm) {
                NeedleFormView(title: "새 바늘 등록") { needleFormData in
                    guard let needle = await onCreateNeedle?(needleFormData) else {
                        return false
                    }

                    formData.selectNeedle(needle)
                    return true
                }
            }
            .sheet(isPresented: $isShowingNewToolForm) {
                ToolFormView(title: "새 도구 등록") { toolFormData in
                    guard let tool = await onCreateTool?(toolFormData) else {
                        return false
                    }

                    if !formData.isToolSelected(tool) {
                        formData.toggleTool(tool)
                    }

                    return true
                }
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
