//
//  YarnFormView.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import SwiftUI

struct YarnFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: YarnFormData
    @State private var validationMessage: String?
    @State private var isShowingDeleteConfirmation = false

    let title: String
    let showsDeleteButton: Bool
    let onSave: (YarnFormData) async -> Bool
    let onDelete: (() async -> Void)?

    init(
        title: String,
        formData: YarnFormData = YarnFormData(),
        showsDeleteButton: Bool = false,
        onSave: @escaping (YarnFormData) async -> Bool,
        onDelete: (() async -> Void)? = nil
    ) {
        self.title = title
        _formData = State(initialValue: formData)
        self.showsDeleteButton = showsDeleteButton
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("기본 정보") {
                TextField("실 이름", text: $formData.name)
                TextField("브랜드", text: $formData.brand)
                TextField("색상명", text: $formData.colorName)
                TextField("색상 번호", text: $formData.colorCode)
                TextField("굵기", text: $formData.weight)
            }

            Section("상세 정보") {
                TextField("길이(m)", text: $formData.lengthMeters)
                    .keyboardType(.decimalPad)

                TextField("혼용률", text: $formData.fiberContent)

                TextField("보유 수량", text: $formData.quantity)
                    .keyboardType(.numberPad)
            }

            Section("게이지 메모") {
                TextEditor(text: $formData.gaugeMemo)
                    .frame(minHeight: 88)
            }

            Section("메모") {
                TextEditor(text: $formData.memo)
                    .frame(minHeight: 100)
            }

            if showsDeleteButton {
                Section {
                    Button("삭제", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(title)
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
                        guard formData.canSave else {
                            validationMessage = "실 이름은 비워둘 수 없어요."
                            return
                        }

                        let didSave = await onSave(formData)

                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("실을 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
            Button("취소", role: .cancel) {
            }

            Button("삭제", role: .destructive) {
                Task {
                    await onDelete?()
                    dismiss()
                }
            }
        } message: {
            Text("삭제한 실 정보는 복구할 수 없어요.")
        }
    }
}

#Preview {
    NavigationStack {
        YarnFormView(title: "실 추가") { _ in true }
    }
}
