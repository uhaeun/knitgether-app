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

    let project: KnittingProject
    let availableYarns: [Yarn]
    let availableNeedles: [Needle]
    let onSave: (ProjectFormData) async -> Bool
    let onDelete: (() async -> Bool)?

    init(
        project: KnittingProject,
        availableYarns: [Yarn] = [],
        availableNeedles: [Needle] = [],
        onSave: @escaping (ProjectFormData) async -> Bool,
        onDelete: (() async -> Bool)? = nil
    ) {
        self.project = project
        self.availableYarns = availableYarns
        self.availableNeedles = availableNeedles
        self.onSave = onSave
        self.onDelete = onDelete
        _formData = State(initialValue: ProjectFormData(project: project))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ProjectFormView(
                    formData: $formData,
                    includesPatternName: false,
                    availableYarns: availableYarns,
                    availableNeedles: availableNeedles
                )
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
                        dismiss()
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
                            dismiss()
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
