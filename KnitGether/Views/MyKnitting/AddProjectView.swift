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

    let onSave: (ProjectFormData) -> Void

    var body: some View {
        NavigationStack {
            ProjectFormView(
                formData: $formData,
                includesPatternName: true
            )
            .navigationTitle("프로젝트 추가")
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
    AddProjectView { _ in }
}
