import SwiftUI

struct KnitAnimationView: View {
    @StateObject private var viewModel: SkillAnimationViewModel
    @StateObject private var dictionaryViewModel: DictionaryViewModel

    init(
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: SkillAnimationViewModel(skillRepository: skillRepository)
        )
        _dictionaryViewModel = StateObject(
            wrappedValue: DictionaryViewModel(dictionaryRepository: dictionaryRepository)
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage ?? dictionaryViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .listRowStyle()
            }

            if viewModel.skills.isEmpty {
                emptyState
                    .listRowStyle()
            } else {
                quickSection(
                    title: "먼저 익혀볼 스킬",
                    description: "스킬 테스트에서 몰라요로 표시한 스킬이에요.",
                    emptyText: "몰라요로 표시된 스킬이 없어요.",
                    skills: viewModel.quickSkills(level: SkillLevelFormatter.unknown)
                )

                quickSection(
                    title: "다시 확인하면 좋은 스킬",
                    description: "아직 헷갈리는 스킬을 다시 확인해보세요.",
                    emptyText: "헷갈려요로 표시된 스킬이 없어요.",
                    skills: viewModel.quickSkills(level: SkillLevelFormatter.unsure)
                )

                Section {
                    controls
                } header: {
                    Text("전체 스킬")
                }
                .listRowStyle()

                if viewModel.displayedSkills.isEmpty {
                    filteredEmptyState
                        .listRowStyle()
                } else {
                    Section {
                        ForEach(viewModel.displayedSkills) { skill in
                            NavigationLink {
                                SkillAnimationDetailView(
                                    skill: skill,
                                    viewModel: viewModel,
                                    dictionaryViewModel: dictionaryViewModel,
                                    dictionaryTerms: dictionaryViewModel.terms,
                                    allSkills: viewModel.skills,
                                    skillAnimations: viewModel.skillAnimations
                                )
                            } label: {
                                SkillAnimationCardView(
                                    skill: skill,
                                    animations: viewModel.animations(for: skill),
                                    level: viewModel.levelDisplayName(skill.userLevel)
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowStyle()
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .warmScreenBackground()
        .navigationTitle("뜨개 애니메이션")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "스킬명, 약어, 설명 검색")
        .task {
            await viewModel.loadSkills()
            await dictionaryViewModel.loadTerms()
        }
        .alert("오류", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? dictionaryViewModel.errorMessage ?? "")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Picker("필터", selection: $viewModel.levelFilter) {
                    ForEach(SkillAnimationViewModel.LevelFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)

                Picker("정렬", selection: $viewModel.sortOption) {
                    ForEach(SkillAnimationViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("전체 \(viewModel.skills.count)개 · 표시 \(viewModel.displayedSkills.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "등록된 스킬이 없어요.",
            description: "스킬 창고에서 스킬을 추가하거나 서버 저장 상태를 다시 확인해 주세요.",
            systemImage: "play.rectangle",
            action: {
                Task {
                    await viewModel.loadSkills()
                }
            }
        ) {
                Label("다시 불러오기", systemImage: "arrow.clockwise")
        }
    }

    private var filteredEmptyState: some View {
        EmptyStateView(
            title: "조건에 맞는 스킬이 없어요.",
            description: "검색어 또는 필터를 바꿔서 다시 확인해보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private func quickSection(
        title: String,
        description: String,
        emptyText: String,
        skills: [Skill]
    ) -> some View {
        Section {
            if skills.isEmpty {
                Text(emptyText)
                    .foregroundStyle(.secondary)
                    .listRowStyle()
            } else {
                ForEach(skills) { skill in
                    NavigationLink {
                        SkillAnimationDetailView(
                            skill: skill,
                            viewModel: viewModel,
                            dictionaryViewModel: dictionaryViewModel,
                            dictionaryTerms: dictionaryViewModel.terms,
                            allSkills: viewModel.skills,
                            skillAnimations: viewModel.skillAnimations
                        )
                    } label: {
                        SkillAnimationCardView(
                            skill: skill,
                            animations: viewModel.animations(for: skill),
                            level: viewModel.levelDisplayName(skill.userLevel)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowStyle()
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(description)
                    .font(.caption)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil || dictionaryViewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                    dictionaryViewModel.clearError()
                }
            }
        )
    }
}

private struct SkillAnimationCardView: View {
    let skill: Skill
    let animations: [SkillAnimation]
    let level: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Text(skill.abbreviation)
                    .font(.title3.bold())
                    .monospaced()
                    .frame(width: 64, height: 48)
                    .background(SkillLevelFormatter.color(for: level).opacity(0.16), in: RoundedRectangle(cornerRadius: 8))

                Text(level)
                    .font(.caption2.bold())
                    .foregroundStyle(SkillLevelFormatter.color(for: level))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(skill.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    if !animations.isEmpty {
                        Text("\(animations.count)개 클립")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(skill.description.isEmpty ? "설명이 아직 없어요." : skill.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .appCard()
    }
}
