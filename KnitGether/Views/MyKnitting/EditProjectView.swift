//
//  EditProjectView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: ProjectFormData
    @State private var isShowingDeleteConfirmation = false
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var submissionErrorMessage: String?
    @State private var isShowingNewYarnForm = false
    @State private var isShowingNewNeedleForm = false

    let project: KnittingProject
    let availableYarns: [Yarn]
    let availableNeedles: [Needle]
    let onSave: (ProjectFormData) async -> Bool
    /// 저장 실패 시 화면이 판단한 안내 문구. 없으면 일반 문구를 쓴다.
    let saveFailureMessage: (() -> String?)?
    let onDelete: (() async -> Bool)?
    let onCreateYarn: ((YarnFormData) async -> Yarn?)?
    let onCreateNeedle: ((NeedleFormData) async -> Needle?)?

    init(
        project: KnittingProject,
        availableYarns: [Yarn] = [],
        availableNeedles: [Needle] = [],
        onSave: @escaping (ProjectFormData) async -> Bool,
        saveFailureMessage: (() -> String?)? = nil,
        onDelete: (() async -> Bool)? = nil,
        onCreateYarn: ((YarnFormData) async -> Yarn?)? = nil,
        onCreateNeedle: ((NeedleFormData) async -> Needle?)? = nil
    ) {
        self.project = project
        self.availableYarns = availableYarns
        self.availableNeedles = availableNeedles
        self.onSave = onSave
        self.saveFailureMessage = saveFailureMessage
        self.onDelete = onDelete
        self.onCreateYarn = onCreateYarn
        self.onCreateNeedle = onCreateNeedle
        _formData = State(initialValue: ProjectFormData(project: project))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ProjectFormView(
                        formData: $formData,
                        includesPatternName: false,
                        availableYarns: availableYarns,
                        availableNeedles: availableNeedles,
                        onRegisterYarn: onCreateYarn == nil ? nil : { isShowingNewYarnForm = true },
                        onRegisterNeedle: onCreateNeedle == nil ? nil : { isShowingNewNeedleForm = true }
                    )

                    if let submissionErrorMessage {
                        AppFormErrorBanner(message: submissionErrorMessage)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)

                if let onDelete {
                    deleteSection(onDelete: onDelete)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.md)
                }
            }
            .padding(.bottom, 96)
            .warmScreenBackground()
            .navigationTitle("프로젝트 수정")
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
                        // 시트가 모달이라 뒤의 오류 배너가 가려진다. 화면이 아는 실제 원인을
                        // 넘겨받아 그대로 보여준다(DEF-24). 예전에는 원인과 무관하게
                        // "입력값과 서버 연결을 확인해 주세요"라고 했는데, 다른 기기와의
                        // 저장 충돌은 입력값 문제도 연결 문제도 아니다.
                        submissionErrorMessage = saveFailureMessage?()
                            ?? "프로젝트 변경사항을 저장하지 못했어요. 입력값과 서버 연결을 확인해 주세요."
                    }
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("변경사항 저장", systemImage: "checkmark")
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

    private func deleteSection(onDelete: @escaping () async -> Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("관리", description: "프로젝트를 삭제하면 작업 기록과 연결 정보도 함께 정리돼요.")

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Color.rose)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.Color.roseSoft, in: RoundedRectangle(cornerRadius: AppTheme.Radius.small))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("프로젝트 삭제")
                            .font(.headline)

                        Text("삭제한 프로젝트는 복구할 수 없어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("삭제", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(AppAccessibilityID.Project.deleteButton)
                    .disabled(isDeleting)
                }
            }
            .padding(AppTheme.Spacing.md)
            .appCard()
            .alert("프로젝트를 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
                Button("취소", role: .cancel) {
                }

                Button("삭제", role: .destructive) {
                    Task {
                        isDeleting = true
                        let didDelete = await onDelete()
                        isDeleting = false

                        if didDelete {
                            submissionErrorMessage = nil
                            dismiss()
                        } else {
                            submissionErrorMessage = "프로젝트를 삭제하지 못했어요. 서버 연결을 확인해 주세요."
                        }
                    }
                }
                .accessibilityIdentifier(AppAccessibilityID.Project.deleteButton)
                .disabled(isDeleting)
            } message: {
                Text("삭제한 프로젝트는 복구할 수 없어요.")
            }
        }
    }
}

#Preview {
    EditProjectView(project: SampleData.projects[0]) { _ in true }
}
