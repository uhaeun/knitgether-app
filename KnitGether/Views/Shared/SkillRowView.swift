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
                Text(skill.name)
                    .font(.headline)

                Text(skill.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
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

#Preview {
    SkillRowView(skill: SampleData.skills[0])
        .padding()
}
