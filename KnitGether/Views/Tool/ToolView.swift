//
//  ToolView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ToolView: View {
    private let skillRepository: any SkillRepository

    init(repositories: AppRepositoryContainer) {
        skillRepository = repositories.skillRepository
    }

    var body: some View {
        List {
            AppNavigationRow(
                item: NavigationRowItem(
                    title: "게이지 계산기",
                    subtitle: "코와 단수를 계산합니다",
                    systemImage: "function"
                )
            ) {
                GaugeCalculatorView()
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "뜨개니게이션",
                    subtitle: "약어와 기법을 빠르게 찾습니다",
                    systemImage: "signpost.right"
                )
            ) {
                SkillToolListView(skillRepository: skillRepository, mode: .navigation)
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "뜨개 사전",
                    subtitle: "뜨개 용어를 찾아봅니다",
                    systemImage: "text.book.closed"
                )
            ) {
                SkillToolListView(skillRepository: skillRepository, mode: .dictionary)
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "뜨개 애니메이션",
                    subtitle: "스킬 동작을 확인합니다",
                    systemImage: "play.rectangle"
                )
            ) {
                SkillToolListView(skillRepository: skillRepository, mode: .animations)
            }
        }
        .navigationTitle("Tool")
    }
}

#Preview {
    NavigationStack {
        ToolView(repositories: .shared)
    }
}
