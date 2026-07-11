import Foundation

struct SkillAnimationFrameSequence: Hashable {
    let title: String
    let frames: [SkillAnimationFrame]

    static func make(abbreviation: String, steps: [String]) -> SkillAnimationFrameSequence {
        let normalizedAbbreviation = abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let resolvedSteps = steps.isEmpty ? ["스킬 설명을 확인하며 천천히 동작을 따라 해보세요."] : steps

        return SkillAnimationFrameSequence(
            title: "\(normalizedAbbreviation.isEmpty ? "스킬" : normalizedAbbreviation) 기본 프레임",
            frames: resolvedSteps.enumerated().map { index, step in
                SkillAnimationFrame(
                    index: index,
                    instruction: step,
                    needleAngleDegrees: index.isMultiple(of: 2) ? -18 : 18,
                    yarnOffset: Double((index % 3) - 1) * 18,
                    activeStitchIndex: index % 5,
                    stitchCount: 5
                )
            }
        )
    }
}

struct SkillAnimationFrame: Identifiable, Hashable {
    let index: Int
    let instruction: String
    let needleAngleDegrees: Double
    let yarnOffset: Double
    let activeStitchIndex: Int
    let stitchCount: Int

    var id: Int {
        index
    }
}
