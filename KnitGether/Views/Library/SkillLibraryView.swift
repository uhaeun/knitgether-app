//
//  SkillLibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct SkillLibraryView: View {
    @StateObject private var viewModel: SkillLibraryViewModel
    @State private var isShowingAddSkill = false

    init(skillRepository: any SkillRepository) {
        _viewModel = StateObject(
            wrappedValue: SkillLibraryViewModel(skillRepository: skillRepository)
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if viewModel.skills.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.skills) { skill in
                    NavigationLink {
                        SkillDetailView(skill: skill)
                    } label: {
                        SkillRowView(skill: skill)
                    }
                }
            }
        }
        .navigationTitle("스킬 창고")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddSkill = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddSkill) {
            AddSkillView { formData in
                await viewModel.addSkill(from: formData)
            }
        }
        .task {
            await viewModel.loadSkills()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아직 등록된 스킬이 없어요.")
                .font(.headline)

            Text("자주 보는 뜨개 약어와 기법을 추가해 보세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        SkillLibraryView(skillRepository: AppRepositoryContainer.shared.skillRepository)
    }
}
