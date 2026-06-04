//
//  ProjectFormView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ProjectFormView: View {
    @Binding var formData: ProjectFormData
    let includesPatternName: Bool

    var body: some View {
        Section("프로젝트") {
            TextField("프로젝트 이름", text: $formData.name)

            Picker("상태", selection: $formData.status) {
                ForEach(ProjectStatus.allCases) { status in
                    Text(status.detailTitle).tag(status)
                }
            }

            DatePicker(
                "시작일",
                selection: $formData.startDate,
                displayedComponents: .date
            )

            Toggle("즐겨찾기", isOn: $formData.isFavorite)
        }

        Section("작업 메모") {
            TextEditor(text: $formData.memo)
                .frame(minHeight: 120)
        }

        if includesPatternName {
            Section("도안") {
                TextField("도안 이름 선택 입력", text: $formData.patternName)

                if formData.trimmedPatternName.isEmpty {
                    Label("도안 없음", systemImage: "doc.badge.plus")
                        .foregroundStyle(.secondary)
                } else {
                    Label("프로젝트에 도안 사본이 저장돼요.", systemImage: "doc.text.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ProjectFormPreview()
}

private struct ProjectFormPreview: View {
    @State private var formData = ProjectFormData()

    var body: some View {
        List {
            ProjectFormView(formData: $formData, includesPatternName: true)
        }
    }
}
