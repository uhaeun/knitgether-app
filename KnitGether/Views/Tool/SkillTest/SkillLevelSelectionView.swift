import SwiftUI

struct SkillLevelSelectionView: View {
    let selectedLevel: String
    let levelOptions: [SkillTestViewModel.LevelOption]
    let selectLevel: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(levelOptions) { option in
                Button {
                    selectLevel(option.id)
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(SkillLevelFormatter.color(for: option.id))
                            .frame(width: 10, height: 10)

                        Text(option.name)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(
                        SkillLevelFormatter.color(for: option.id).opacity(isSelected(option.id) ? 0.24 : 0.08),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected(option.id)
                                    ? SkillLevelFormatter.color(for: option.id)
                                    : Color.secondary.opacity(0.18),
                                lineWidth: isSelected(option.id) ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isSelected(_ level: String) -> Bool {
        SkillLevelFormatter.normalizedLevel(selectedLevel) == level
    }
}
