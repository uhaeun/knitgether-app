import SwiftUI

struct KnitDictionaryView: View {
    @StateObject private var viewModel: DictionaryViewModel
    @State private var skills: [Skill] = []
    @State private var skillAnimations: [SkillAnimation] = []
    @State private var skillLoadError: String?

    private let skillRepository: any SkillRepository

    init(
        dictionaryRepository: any DictionaryRepository,
        skillRepository: any SkillRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: DictionaryViewModel(dictionaryRepository: dictionaryRepository)
        )
        self.skillRepository = skillRepository
    }

    var body: some View {
        List {
            Section {
                controls
            }
            .listRowStyle()

            if let errorMessage = viewModel.errorMessage ?? skillLoadError {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .listRowStyle()
            }

            if viewModel.terms.isEmpty {
                emptyState
                    .listRowStyle()
            } else if viewModel.displayedTerms.isEmpty {
                filteredEmptyState
                    .listRowStyle()
            } else {
                Section {
                    ForEach(viewModel.displayedTerms) { term in
                        NavigationLink {
                            DictionaryTermDetailView(
                                term: term,
                                viewModel: viewModel,
                                skills: skills,
                                skillAnimations: skillAnimations
                            )
                        } label: {
                            DictionaryTermCardView(term: term, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.dictionaryTermRow(term.term))
                        .listRowStyle()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .warmScreenBackground()
        .navigationTitle("뜨개 사전")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "용어, 약어, 설명 검색")
        .task {
            await load()
        }
        .alert("오류", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? skillLoadError ?? "")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Picker("필터", selection: $viewModel.filterOption) {
                    ForEach(DictionaryViewModel.FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)

                Picker("정렬", selection: $viewModel.sortOption) {
                    ForEach(DictionaryViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("전체 \(viewModel.terms.count)개 · 표시 \(viewModel.displayedTerms.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(AppAccessibilityID.Tool.dictionaryCountLabel)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "등록된 사전 용어가 없어요.",
            description: "서버 저장 데이터 또는 로컬 샘플 데이터를 다시 불러와 주세요.",
            systemImage: "text.book.closed",
            action: {
                Task {
                    await load()
                }
            }
        ) {
                Label("다시 불러오기", systemImage: "arrow.clockwise")
        }
    }

    private var filteredEmptyState: some View {
        EmptyStateView(
            title: "조건에 맞는 용어가 없어요.",
            description: "검색어 또는 필터를 바꿔서 다시 확인해보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil || skillLoadError != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                    skillLoadError = nil
                }
            }
        )
    }

    private func load() async {
        await viewModel.loadTerms()

        do {
            skills = try await skillRepository.fetchSkills()
            skillAnimations = try await skillRepository.fetchSkillAnimations()
            skillLoadError = nil
        } catch {
            skillLoadError = "관련 스킬을 불러오지 못했어요."
        }
    }
}

struct DictionaryTermCardView: View {
    let term: DictionaryTerm
    let viewModel: DictionaryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(term.term)
                    .font(.headline)
                    .monospaced()

                if let fullName = term.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(term.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if !viewModel.parseRelatedSkillAbbreviations(term.relatedSkillAbbreviations).isEmpty {
                Label(term.relatedSkillAbbreviations, systemImage: "tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .appCard()
    }
}

struct DictionaryTermDetailView: View {
    let term: DictionaryTerm
    @ObservedObject var viewModel: DictionaryViewModel
    let skills: [Skill]
    let skillAnimations: [SkillAnimation]

    @State private var selectedSkill: Skill?
    @State private var unregisteredSkillTag: String?

    private var resolvedSkills: [ResolvedSkillTag] {
        viewModel.resolveRelatedSkills(for: term, skills: skills)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                descriptionSection
                DictionaryRelatedSkillView(resolvedTags: resolvedSkills, tapAction: handleSkillTap)
                infoSection
            }
            .padding()
        }
        .warmScreenBackground()
        .navigationTitle("사전 상세")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSkill) { skill in
            NavigationStack {
                SkillDetailView(
                    skill: skill,
                    animations: animations(for: skill)
                )
            }
        }
        .alert("미등록 스킬", isPresented: unregisteredSkillBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("'\(unregisteredSkillTag ?? "")'은 아직 스킬 창고에 등록되지 않은 스킬이에요.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(term.term)
                .font(.largeTitle.bold())
                .monospaced()

            if let fullName = term.fullName, !fullName.isEmpty {
                Text(fullName)
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("뜻")
                .font(.headline)

            Text(term.description)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard()
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정보")
                .font(.headline)

            DictionaryInfoRow(title: "용어", value: term.term)
            DictionaryInfoRow(title: "전체 이름", value: term.fullName ?? "없음")
            DictionaryInfoRow(title: "관련 스킬", value: term.relatedSkillAbbreviations.isEmpty ? "없음" : term.relatedSkillAbbreviations)
            DictionaryInfoRow(title: "생성일", value: viewModel.formattedDate(term.createdAt))
            DictionaryInfoRow(title: "수정일", value: viewModel.formattedDate(term.updatedAt))
        }
        .padding()
        .appCard()
    }

    private var unregisteredSkillBinding: Binding<Bool> {
        Binding(
            get: { unregisteredSkillTag != nil },
            set: { isPresented in
                if !isPresented {
                    unregisteredSkillTag = nil
                }
            }
        )
    }

    private func handleSkillTap(_ tag: ResolvedSkillTag) {
        if let skill = tag.skill {
            selectedSkill = skill
        } else {
            unregisteredSkillTag = tag.displayTag
        }
    }

    private func animations(for skill: Skill) -> [SkillAnimation] {
        skillAnimations.filter { animation in
            animation.skillId == skill.id || skill.animationIds.contains(animation.id)
        }
    }
}

private struct DictionaryRelatedSkillView: View {
    let resolvedTags: [ResolvedSkillTag]
    let tapAction: (ResolvedSkillTag) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("관련 스킬")
                .font(.headline)

            if resolvedTags.isEmpty {
                Text("연결된 스킬이 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(resolvedTags) { tag in
                    Button {
                        tapAction(tag)
                    } label: {
                        relatedSkillRow(tag)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .appCard()
    }

    private func relatedSkillRow(_ tag: ResolvedSkillTag) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(tag.displayTag)
                .font(.headline)
                .monospaced()
                .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                if let skill = tag.skill {
                    Text(skill.name)
                        .font(.subheadline.bold())

                    Text(skill.description.isEmpty ? "설명이 아직 없어요." : skill.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(SkillLevelFormatter.normalizedLevel(skill.userLevel))
                        .font(.caption.bold())
                        .foregroundStyle(SkillLevelFormatter.color(for: skill.userLevel))
                } else {
                    Text("미등록 스킬")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    Text("스킬 창고에 아직 등록되지 않았어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: tag.isRegistered ? "chevron.right" : "exclamationmark.circle")
                .font(.caption.bold())
                .foregroundStyle(tag.isRegistered ? Color.secondary : Color.gray)
        }
        .padding(.vertical, 6)
    }
}

private struct DictionaryInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        KnitDictionaryView(
            dictionaryRepository: AppRepositoryContainer.shared.dictionaryRepository,
            skillRepository: AppRepositoryContainer.shared.skillRepository
        )
    }
}
