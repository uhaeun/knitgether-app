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
    @State private var skillPendingEdit: Skill?
    @State private var skillPendingDeletion: Skill?
    @State private var isShowingDeleteConfirmation = false

    init(skillRepository: any SkillRepository) {
        _viewModel = StateObject(
            wrappedValue: SkillLibraryViewModel(skillRepository: skillRepository)
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
                    .listRowStyle()
            }

            if viewModel.hasSkillsNeedingSync {
                syncRetryRow
                    .listRowStyle()
            }

            if viewModel.skills.isEmpty {
                emptyState
                    .listRowStyle()
            } else {
                if viewModel.filteredSkills.isEmpty {
                    searchEmptyState
                        .listRowStyle()
                }

                ForEach(viewModel.filteredSkills) { skill in
                    NavigationLink {
                        SkillDetailView(skill: skill)
                    } label: {
                        SkillRowView(skill: skill)
                            .padding(12)
                            .appCard()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AppAccessibilityID.Library.skillRow(skill.id))
                    .listRowStyle()
                    .swipeActions(edge: .trailing) {
                        if !skill.isSystem {
                            Button(role: .destructive) {
                                skillPendingDeletion = skill
                                isShowingDeleteConfirmation = true
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }

                            Button {
                                skillPendingEdit = skill
                            } label: {
                                Label("수정", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("스킬 창고")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "스킬 이름, 약어, 설명 검색"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasSkillsNeedingSync {
                    Button {
                        Task {
                            await viewModel.retrySync()
                        }
                    } label: {
                        if viewModel.isRetryingSync {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(viewModel.isRetryingSync)
                    .accessibilityLabel("스킬 창고 저장 상태 다시 확인")
                }

                Button {
                    isShowingAddSkill = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Library.skillAddButton)
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddSkill) {
            AddSkillView { formData in
                await viewModel.addSkill(from: formData)
            }
        }
        .sheet(item: $skillPendingEdit) { skill in
            AddSkillView(skill: skill) { formData in
                await viewModel.updateSkill(skill, from: formData)
            }
        }
        .alert("스킬을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: skillPendingDeletion) { skill in
            Button("취소", role: .cancel) {
                skillPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteSkill(skill)

                    if didDelete {
                        skillPendingDeletion = nil
                    }
                }
            }
        } message: { skill in
            Text("\(skill.name)을 스킬 창고에서 삭제해요.")
        }
        .task {
            await viewModel.loadSkills()
        }
        .refreshable {
            await viewModel.loadSkills()
        }
        .warmScreenBackground()
    }

    private var syncRetryRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Label("계정 저장 확인이 필요한 스킬이 있어요.", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task {
                    await viewModel.retrySync()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRetryingSync)
        }
        .padding(.vertical, 6)
    }

    private func errorRow(message: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)

            Spacer()

            Button {
                Task {
                    await viewModel.retrySync()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRetryingSync)
        }
    }

    private var searchEmptyState: some View {
        EmptyStateView(
            title: "검색 결과가 없어요.",
            description: "스킬 이름, 약어, 설명을 바꿔 다시 찾아보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "아직 등록된 스킬이 없어요.",
            description: "자주 보는 뜨개 약어와 기법을 추가하고 스킬 테스트 결과와 함께 관리해 보세요.",
            systemImage: "graduationcap",
            action: {
                isShowingAddSkill = true
            }
        ) {
            Label("스킬 추가", systemImage: "plus")
        }
    }
}

#Preview {
    NavigationStack {
        SkillLibraryView(skillRepository: AppRepositoryContainer.shared.skillRepository)
    }
}
