//
//  ToolView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ToolView: View {
    private let authSessionStore: AuthSessionStore
    private let projectRepository: any ProjectRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let gaugeTargetRepository: any GaugeTargetRepository
    private let patternRepository: any PatternRepository
    private let skillRepository: any SkillRepository
    private let dictionaryRepository: any DictionaryRepository

    init(repositories: AppRepositoryContainer) {
        authSessionStore = repositories.authSessionStore
        projectRepository = repositories.projectRepository
        gaugeRecordRepository = repositories.gaugeRecordRepository
        gaugeTargetRepository = repositories.gaugeTargetRepository
        patternRepository = repositories.patternRepository
        skillRepository = repositories.skillRepository
        dictionaryRepository = repositories.dictionaryRepository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                AppNavigationList {
                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "게이지 계산기",
                            subtitle: "코 수 · 단 수 · 치수",
                            systemImage: "ruler.fill",
                            tint: AppTheme.Color.accent
                        )
                    ) {
                        GaugeCalculatorView(
                            authSessionStore: authSessionStore,
                            gaugeRecordRepository: gaugeRecordRepository,
                            gaugeTargetRepository: gaugeTargetRepository,
                            projectRepository: projectRepository,
                            patternRepository: patternRepository
                        )
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeCalculatorCard)

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "스킬 테스트",
                            subtitle: "몰라요 · 헷갈려요 · 잘 알아요",
                            systemImage: "checklist",
                            tint: AppTheme.Color.sage
                        )
                    ) {
                        SkillTestView(skillRepository: skillRepository)
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Tool.skillTestCard)

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "뜨개니게이션",
                            subtitle: "약어 · 기법 검색",
                            systemImage: "signpost.right.fill",
                            tint: AppTheme.Color.amber
                        )
                    ) {
                        SkillToolListView(skillRepository: skillRepository, mode: .navigation)
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Tool.navigationCard)

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "뜨개 사전",
                            subtitle: "용어 · 관련 스킬",
                            systemImage: "book.closed.fill",
                            tint: AppTheme.Color.slate
                        )
                    ) {
                        KnitDictionaryView(
                            dictionaryRepository: dictionaryRepository,
                            skillRepository: skillRepository
                        )
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Tool.dictionaryCard)

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "뜨개 애니메이션",
                            subtitle: "단계별 학습",
                            systemImage: "play.rectangle.fill",
                            tint: AppTheme.Color.lavender
                        ),
                        showsSeparator: false
                    ) {
                        KnitAnimationView(
                            skillRepository: skillRepository,
                            dictionaryRepository: dictionaryRepository
                        )
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Tool.animationCard)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .warmScreenBackground()
        .navigationTitle("도구")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("도구")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(AppTheme.Color.primaryText)

            Text("계산, 사전, 학습을 한 곳에서 이어가요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        ToolView(repositories: .shared)
    }
}
