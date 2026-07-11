import SwiftUI

struct PatternSupportLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var terms: [DictionaryTerm] = []
    @State private var skills: [Skill] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    let dictionaryRepository: any DictionaryRepository
    let skillRepository: any SkillRepository

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("사전과 스킬을 불러오는 중이에요.")
                            .foregroundStyle(.secondary)
                    }
                    .listRowStyle()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .listRowStyle()
                }

                Section("뜨개 사전") {
                    if filteredTerms.isEmpty {
                        Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "등록된 사전 용어가 없어요." : "검색된 사전 용어가 없어요.")
                            .foregroundStyle(.secondary)
                            .listRowStyle()
                    } else {
                        ForEach(filteredTerms.prefix(20)) { term in
                            NavigationLink {
                                PatternSupportTermDetailView(
                                    term: term,
                                    matchingSkills: skills(for: term),
                                    skillRepository: skillRepository,
                                    dictionaryRepository: dictionaryRepository
                                )
                            } label: {
                                termRow(term)
                            }
                            .buttonStyle(.plain)
                            .listRowStyle()
                        }
                    }
                }

                Section("관련 스킬") {
                    if filteredSkills.isEmpty {
                        Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "등록된 스킬이 없어요." : "검색된 스킬이 없어요.")
                            .foregroundStyle(.secondary)
                            .listRowStyle()
                    } else {
                        ForEach(filteredSkills.prefix(20)) { skill in
                            NavigationLink {
                                WorkspaceSkillLearningView(
                                    skill: skill,
                                    skillRepository: skillRepository,
                                    dictionaryRepository: dictionaryRepository
                                )
                            } label: {
                                SkillRowView(skill: skill)
                                    .padding(12)
                                    .appCard()
                            }
                            .buttonStyle(.plain)
                            .listRowStyle()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Color.warmBackground)
            .navigationTitle("도안 보며 찾아보기")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "약어, 용어, 기법 검색")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .task {
                await load()
            }
        }
    }

    private var filteredTerms: [DictionaryTerm] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = terms.sorted { first, second in
            first.term.localizedStandardCompare(second.term) == .orderedAscending
        }

        guard !query.isEmpty else {
            return Array(source.prefix(12))
        }

        return source.filter { term in
            term.term.localizedCaseInsensitiveContains(query)
                || term.fullName?.localizedCaseInsensitiveContains(query) == true
                || term.description.localizedCaseInsensitiveContains(query)
                || term.relatedSkillAbbreviations.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredSkills: [Skill] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = skills.sorted { first, second in
            first.abbreviation.localizedStandardCompare(second.abbreviation) == .orderedAscending
        }

        guard !query.isEmpty else {
            return Array(source.prefix(12))
        }

        return source.filter { skill in
            skill.abbreviation.localizedCaseInsensitiveContains(query)
                || skill.name.localizedCaseInsensitiveContains(query)
                || skill.description.localizedCaseInsensitiveContains(query)
                || skill.category?.localizedCaseInsensitiveContains(query) == true
        }
    }

    private func termRow(_ term: DictionaryTerm) -> some View {
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

                Spacer(minLength: 12)

                SyncStatusBadgeView(status: term.syncStatus)
            }

            Text(term.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if !term.relatedSkillAbbreviations.isEmpty {
                AppMetricChip(
                    text: term.relatedSkillAbbreviations,
                    systemImage: "tag",
                    tint: AppTheme.Color.sage
                )
            }
        }
        .padding(12)
        .appCard()
    }

    private func skills(for term: DictionaryTerm) -> [Skill] {
        let tags = term.relatedSkillAbbreviations
            .split { character in
                character == "," || character == " " || character == "\n"
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return tags.compactMap { tag in
            skills.first { skill in
                skill.abbreviation.caseInsensitiveCompare(tag) == .orderedSame
            }
        }
    }

    private func load() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            async let loadedTerms = dictionaryRepository.fetchTerms()
            async let loadedSkills = skillRepository.fetchSkills()
            terms = try await loadedTerms
            skills = try await loadedSkills
            errorMessage = nil
        } catch {
            errorMessage = "사전과 스킬을 불러오지 못했어요."
        }
    }
}

private struct PatternSupportTermDetailView: View {
    let term: DictionaryTerm
    let matchingSkills: [Skill]
    let skillRepository: any SkillRepository
    let dictionaryRepository: any DictionaryRepository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AppDetailHeaderView(
                    title: term.term,
                    subtitle: term.fullName,
                    systemImage: "text.book.closed",
                    tint: AppTheme.Color.accent
                ) {
                    SyncStatusBadgeView(status: term.syncStatus)
                }

                detailSection(title: "뜻") {
                    Text(term.description)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                detailSection(title: "관련 스킬") {
                    if matchingSkills.isEmpty {
                        Text("연결된 스킬이 없어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matchingSkills) { skill in
                            NavigationLink {
                                WorkspaceSkillLearningView(
                                    skill: skill,
                                    skillRepository: skillRepository,
                                    dictionaryRepository: dictionaryRepository
                                )
                            } label: {
                                SkillRowView(skill: skill)
                                    .padding(12)
                                    .background(AppTheme.Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                detailSection(title: "정보") {
                    AppDetailInfoRow(title: "용어", value: term.term, systemImage: "textformat")
                    AppDetailInfoRow(title: "전체 이름", value: term.fullName ?? "없음", systemImage: "text.quote")
                    AppDetailInfoRow(
                        title: "스킬 태그",
                        value: term.relatedSkillAbbreviations.isEmpty ? "없음" : term.relatedSkillAbbreviations,
                        systemImage: "tag"
                    )
                }
            }
            .padding()
        }
        .warmScreenBackground()
        .navigationTitle("사전 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(title)
            AppSoftPanel {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
            }
        }
    }
}
