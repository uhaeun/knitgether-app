//
//  SkillRowView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct SkillRowView: View {
    let skill: Skill

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(skill.abbreviation)
                .font(.subheadline)
                .fontWeight(.bold)
                .monospaced()
                .frame(width: 48, height: 34)
                .background(Color.accentColor.opacity(0.14))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(skill.name)
                        .font(.headline)

                    SyncStatusBadgeView(status: skill.syncStatus)
                }

                Text(skill.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    SkillLevelBadgeView(level: skill.userLevel)

                    if let category = skill.category {
                        Text(category)
                    }

                    if let difficulty = skill.difficulty {
                        Text(difficulty)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SkillLevelBadgeView: View {
    let level: String?

    private var normalizedLevel: String {
        SkillLevelFormatter.normalizedLevel(level)
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(SkillLevelFormatter.color(for: normalizedLevel))
                .frame(width: 8, height: 8)

            Text(normalizedLevel)
                .font(.caption2.bold())
        }
        .foregroundStyle(SkillLevelFormatter.color(for: normalizedLevel))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            SkillLevelFormatter.color(for: normalizedLevel).opacity(0.14),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(SkillLevelFormatter.color(for: normalizedLevel).opacity(0.45))
        }
        .accessibilityLabel("스킬 이해도 \(normalizedLevel)")
    }
}

#Preview {
    SkillRowView(skill: SampleData.skills[0])
        .padding()
}
