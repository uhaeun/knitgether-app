//
//  SkillDetailView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct SkillDetailView: View {
    let skill: Skill

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
                    animationPlaceholder
                }
            }
            .padding()
        }
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
                if let category = skill.category {
                    metadataChip(category)
                }

                if let difficulty = skill.difficulty {
                    metadataChip(difficulty)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var animationPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.animationName ?? "\(skill.name) 애니메이션")
                        .font(.headline)

                    Text("동작 애니메이션은 다음 단계에서 연결됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            Label(title, systemImage: systemImage)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SkillDetailView(skill: SampleData.skills[0])
    }
}
