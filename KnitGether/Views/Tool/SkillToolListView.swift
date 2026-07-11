//
//  SkillToolListView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

enum SkillToolMode: Equatable {
    case navigation
    case dictionary
    case animations

    var title: String {
        switch self {
        case .navigation:
            return "뜨개니게이션"
        case .dictionary:
            return "뜨개 사전"
        case .animations:
            return "뜨개 애니메이션"
        }
    }

    var searchPrompt: String {
        switch self {
        case .navigation:
            return "스킬 이름 또는 약어 검색"
        case .dictionary:
            return "뜨개 용어 검색"
        case .animations:
            return "애니메이션 검색"
        }
    }

    var emptyMessage: String {
        switch self {
        case .navigation:
            return "찾는 스킬이 없어요."
        case .dictionary:
            return "검색 결과가 없어요."
        case .animations:
            return "아직 연결된 애니메이션이 없어요."
        }
    }

}

struct SkillToolListView: View {
    @StateObject private var viewModel: SkillLibraryViewModel
    let mode: SkillToolMode

    init(
        skillRepository: any SkillRepository,
        mode: SkillToolMode
    ) {
        _viewModel = StateObject(
            wrappedValue: SkillLibraryViewModel(skillRepository: skillRepository)
        )
        self.mode = mode
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if displayedSkills.isEmpty {
                Text(mode.emptyMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(displayedSkills) { skill in
                    NavigationLink {
                        SkillDetailView(
                            skill: skill,
                            animations: viewModel.animations(for: skill)
                        )
                    } label: {
                        if mode == .animations {
                            animationCard(for: skill)
                        } else {
                            SkillRowView(skill: skill)
                        }
                    }
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: searchTextBinding,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: mode.searchPrompt
        )
        .task {
            await viewModel.loadSkills()
        }
    }

    private var displayedSkills: [Skill] {
        switch mode {
        case .navigation, .dictionary:
            return viewModel.filteredSkills
        case .animations:
            return SkillLibraryViewModel.filteredSkills(
                viewModel.animationSkills,
                matching: viewModel.searchText
            )
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        )
    }

    private func animationCard(for skill: Skill) -> some View {
        let linkedAnimations = viewModel.animations(for: skill)

        return HStack(spacing: 12) {
            Image(systemName: "play.rectangle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 5) {
                Text(skill.animationName ?? "\(skill.name) 애니메이션")
                    .font(.headline)

                HStack(spacing: 8) {
                    SkillLevelBadgeView(level: skill.userLevel)
                    Text(skill.name)
                    Text(skill.abbreviation)
                        .monospaced()
                    if !linkedAnimations.isEmpty {
                        Text("\(linkedAnimations.count)개 클립")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        SkillToolListView(
            skillRepository: AppRepositoryContainer.shared.skillRepository,
            mode: .navigation
        )
    }
}
