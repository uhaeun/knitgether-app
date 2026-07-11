import SwiftUI

struct SkillTestCardView: View {
    let skill: Skill
    let selectedLevel: String
    let levelOptions: [SkillTestViewModel.LevelOption]
    let selectLevel: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(skill.abbreviation)
                        .font(.largeTitle.bold())
                        .monospaced()

                    Text(skill.name)
                        .font(.title3.bold())
                        .lineLimit(2)
                }

                Text(skill.description.isEmpty ? "설명이 아직 없어요." : skill.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("현재 상태: \(SkillLevelFormatter.normalizedLevel(skill.userLevel))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if !skill.steps.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("기본 흐름")
                        .font(.headline)

                    ForEach(Array(skill.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.accentColor, in: Circle())

                            Text(step)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("이 스킬을 얼마나 알고 있나요?")
                    .font(.headline)

                SkillLevelSelectionView(
                    selectedLevel: selectedLevel,
                    levelOptions: levelOptions,
                    selectLevel: selectLevel
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard()
    }
}
