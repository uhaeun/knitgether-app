//
//  AddSkillView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData = SkillFormData()

    let onSave: (SkillFormData) async -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("스킬 이름", text: $formData.name)
                    TextField("약어", text: $formData.abbreviation)
                        .textInputAutocapitalization(.characters)
                    TextField("카테고리", text: $formData.category)
                    TextField("난이도", text: $formData.difficulty)
                }

                Section("설명") {
                    TextEditor(text: $formData.description)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("스킬 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let didSave = await onSave(formData)

                            if didSave {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!formData.canSave)
                }
            }
        }
    }
}

#Preview {
    AddSkillView { _ in true }
}
