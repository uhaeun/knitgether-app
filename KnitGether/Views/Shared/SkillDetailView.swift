//
//  SkillDetailView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct SkillDetailView: View {
    let skill: Skill
    let animations: [SkillAnimation]

    init(skill: Skill, animations: [SkillAnimation] = []) {
        self.skill = skill
        self.animations = animations
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                detailSection(title: "설명", systemImage: "text.alignleft") {
                    Text(skill.description)
                        .foregroundStyle(.primary)
                }

                if !skill.steps.isEmpty {
                    detailSection(title: "기본 흐름", systemImage: "list.number") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(skill.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .fontWeight(.semibold)

                                    Text(step)
                                }
                            }
                        }
                    }
                }

                detailSection(title: "뜨개 애니메이션", systemImage: "play.rectangle") {
                    animationContent
                }
            }
            .padding()
        }
        .warmScreenBackground()
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(skill.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(skill.abbreviation)
                    .font(.headline)
                    .fontWeight(.bold)
                    .monospaced()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.14))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 8) {
                SkillLevelBadgeView(level: skill.userLevel)

                if let category = skill.category {
                    metadataChip(category)
                }

                if let difficulty = skill.difficulty {
                    metadataChip(difficulty)
                }

                if skill.isSystem {
                    metadataChip("기본 제공")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var animationContent: some View {
        if animations.isEmpty {
            animationPlaceholder
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(animations) { animation in
                    animationRow(animation)
                }
            }
        }
    }

    private func animationRow(_ animation: SkillAnimation) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(animation.title)
                    .font(.headline)

                Text(animationMetadataText(for: animation))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var animationPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: skill.hasAnimationMetadata ? "play.circle" : "play.slash")
                    .font(.system(size: 38))
                    .foregroundStyle(skill.hasAnimationMetadata ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.animationName ?? "등록된 애니메이션 없음")
                        .font(.headline)

                    Text(animationDetailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var animationDetailText: String {
        var components: [String] = []

        if let animationType = skill.animationType, !animationType.isEmpty {
            components.append(animationType)
        }

        if !skill.animationIds.isEmpty {
            components.append("\(skill.animationIds.count)개 클립")
        }

        return components.isEmpty ? "스킬 창고에서 애니메이션 정보를 추가할 수 있어요." : components.joined(separator: " · ")
    }

    private func animationMetadataText(for animation: SkillAnimation) -> String {
        var components: [String] = []

        if let durationSeconds = animation.durationSeconds {
            components.append("\(durationSeconds)초")
        }

        if let localAssetName = animation.localAssetName, !localAssetName.isEmpty {
            components.append(localAssetName)
        }

        return components.isEmpty ? "연결된 애니메이션" : components.joined(separator: " · ")
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }
}

#Preview {
    NavigationStack {
        SkillDetailView(skill: SampleData.skills[0])
    }
}

private extension Skill {
    var hasAnimationMetadata: Bool {
        animationName != nil || animationType != nil || !animationIds.isEmpty
    }
}
