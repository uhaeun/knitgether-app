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

    let project: KnittingProject
    let onSave: (ProjectFormData) -> Void
    let onDelete: (() -> Void)?

    init(
        project: KnittingProject,
        onSave: @escaping (ProjectFormData) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.project = project
        self.onSave = onSave
        self.onDelete = onDelete
        _formData = State(initialValue: ProjectFormData(project: project))
    }

    var body: some View {
        NavigationStack {
            List {
                ProjectFormView(
                    formData: $formData,
                    includesPatternName: false
                )

                if let onDelete {
                    Section {
                        Button("삭제", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                    .alert("프로젝트를 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
                        Button("취소", role: .cancel) {
                        }

                        Button("삭제", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    } message: {
                        Text("삭제한 프로젝트는 복구할 수 없어요.")
                    }
                }
            }
            .navigationTitle("프로젝트 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(formData)
                        dismiss()
                    }
                    .disabled(!formData.canSave)
                }
            }
        }
    }
}

#Preview {
    EditProjectView(project: SampleData.projects[0]) { _ in }
}
