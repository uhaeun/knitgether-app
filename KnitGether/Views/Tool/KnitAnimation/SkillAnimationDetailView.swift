import SwiftUI

struct SkillAnimationDetailView: View {
    let skill: Skill
    @ObservedObject var viewModel: SkillAnimationViewModel
    @ObservedObject var dictionaryViewModel: DictionaryViewModel
    let dictionaryTerms: [DictionaryTerm]
    let allSkills: [Skill]
    let skillAnimations: [SkillAnimation]

    @State private var selectedLevel: String

    private var relatedTerms: [DictionaryTerm] {
        viewModel.relatedDictionaryTerms(for: skill, in: dictionaryTerms)
    }

    init(
        skill: Skill,
        viewModel: SkillAnimationViewModel,
        dictionaryViewModel: DictionaryViewModel,
        dictionaryTerms: [DictionaryTerm],
        allSkills: [Skill],
        skillAnimations: [SkillAnimation]
    ) {
        self.skill = skill
        self.viewModel = viewModel
        self.dictionaryViewModel = dictionaryViewModel
        self.dictionaryTerms = dictionaryTerms
        self.allSkills = allSkills
        self.skillAnimations = skillAnimations
        _selectedLevel = State(initialValue: SkillLevelFormatter.normalizedLevel(skill.userLevel))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                levelSection
                descriptionSection
                SkillLearningStepsView(steps: viewModel.stepDescriptions(for: skill))
                KnitStepAnimationView(sequence: viewModel.frameSequence(for: skill))
                SkillAnimationPlaceholderView(kind: .animation, animations: viewModel.animations(for: skill))
                relatedDictionarySection
            }
            .padding()
        }
        .warmScreenBackground()
        .navigationTitle("스킬 학습")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(skill.abbreviation)
                    .font(.largeTitle.bold())
                    .monospaced()

                Text(selectedLevel)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(SkillLevelFormatter.color(for: selectedLevel).opacity(0.22), in: Capsule())
            }

            Text(skill.name)
                .font(.title3.bold())

            Text("단계별 설명으로 뜨개 스킬을 익혀보세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이해도")
                .font(.headline)

            Picker("이해도", selection: levelBinding) {
                ForEach(SkillLevelFormatter.levels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .appCard()
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("스킬 설명")
                .font(.headline)

            Text(skill.description.isEmpty ? "설명이 아직 없어요." : skill.description)
                .font(.subheadline)

            if let animationName = skill.animationName, !animationName.isEmpty {
                Divider()

                Text(animationName)
                    .font(.subheadline.bold())

                if let animationType = skill.animationType, !animationType.isEmpty {
                    Text(animationType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard()
    }

    private var levelBinding: Binding<String> {
        Binding(
            get: { selectedLevel },
            set: { newLevel in
                selectedLevel = newLevel
                Task {
                    await viewModel.updateSkillLevel(skill, level: newLevel)
                }
            }
        )
    }

    private var relatedDictionarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("관련 사전")
                .font(.headline)

            if relatedTerms.isEmpty {
                Text("연결된 사전 용어가 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(relatedTerms) { term in
                    NavigationLink {
                        DictionaryTermDetailView(
                            term: term,
                            viewModel: dictionaryViewModel,
                            skills: allSkills,
                            skillAnimations: skillAnimations
                        )
                    } label: {
                        DictionaryTermCardView(
                            term: term,
                            viewModel: dictionaryViewModel
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .appCard()
    }
}

private struct SkillLearningStepsView: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("단계별 설명")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard()
    }
}

private struct KnitStepAnimationView: View {
    let sequence: SkillAnimationFrameSequence

    @State private var currentStep = 0
    @State private var isPlaying = true

    private var frames: [SkillAnimationFrame] {
        sequence.frames
    }

    private var currentFrame: SkillAnimationFrame? {
        frames.indices.contains(currentStep) ? frames[currentStep] : frames.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(sequence.title, systemImage: "play.circle")
                    .font(.headline)

                Spacer()

                Text("\(currentStep + 1) / \(max(frames.count, 1))")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            animationCanvas

            Text(currentFrame?.instruction ?? "설명을 준비 중이에요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    currentStep = max(0, currentStep - 1)
                } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(currentStep == 0)

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }

                Button {
                    currentStep = min(max(frames.count - 1, 0), currentStep + 1)
                } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(currentStep >= frames.count - 1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .appCard()
        .task(id: "\(currentStep)-\(isPlaying)") {
            guard isPlaying, frames.count > 1 else {
                return
            }
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled, isPlaying else {
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                currentStep = (currentStep + 1) % frames.count
            }
        }
    }

    private var animationCanvas: some View {
        GeometryReader { geometry in
            let frame = currentFrame
            let width = geometry.size.width
            let activeIndex = frame?.activeStitchIndex ?? 0
            let stitchCount = max(frame?.stitchCount ?? 5, 1)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.warmBackground)

                Path { path in
                    path.move(to: CGPoint(x: width * 0.14, y: 86))
                    path.addCurve(
                        to: CGPoint(x: width * 0.86, y: 78),
                        control1: CGPoint(x: width * 0.35, y: 34 + (frame?.yarnOffset ?? 0)),
                        control2: CGPoint(x: width * 0.64, y: 132 - (frame?.yarnOffset ?? 0))
                    )
                }
                .stroke(AppTheme.Color.amber, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .shadow(color: AppTheme.Color.amber.opacity(0.25), radius: 6, y: 3)
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentStep)

                HStack(spacing: 10) {
                    ForEach(0..<stitchCount, id: \.self) { index in
                        Capsule()
                            .fill(index == activeIndex ? AppTheme.Color.sage : AppTheme.Color.sage.opacity(0.24))
                            .frame(width: index == activeIndex ? 28 : 22, height: index == activeIndex ? 48 : 38)
                            .overlay {
                                Capsule()
                                    .stroke(AppTheme.Color.sage.opacity(0.45), lineWidth: 1)
                            }
                            .offset(y: index == activeIndex ? -8 : 0)
                            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: currentStep)
                    }
                }
                .offset(y: 34)

                NeedleShape()
                    .fill(AppTheme.Color.accent)
                    .frame(width: 150, height: 8)
                    .rotationEffect(.degrees(frame?.needleAngleDegrees ?? -18), anchor: .leading)
                    .offset(x: -34, y: -18)
                    .shadow(color: AppTheme.Color.accent.opacity(0.18), radius: 8, y: 4)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentStep)

                NeedleShape()
                    .fill(AppTheme.Color.slate)
                    .frame(width: 150, height: 8)
                    .rotationEffect(.degrees(-(frame?.needleAngleDegrees ?? -18)), anchor: .trailing)
                    .offset(x: 34, y: -10)
                    .shadow(color: AppTheme.Color.slate.opacity(0.16), radius: 8, y: 4)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentStep)

                VStack {
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(frames.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? AppTheme.Color.accent : Color.secondary.opacity(0.25))
                                .frame(width: index == currentStep ? 9 : 6, height: index == currentStep ? 9 : 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: currentStep)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tipWidth: CGFloat = min(rect.width * 0.18, 28)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SkillAnimationPlaceholderView: View {
    enum PlaceholderKind {
        case animation
    }

    let kind: PlaceholderKind
    let animations: [SkillAnimation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("애니메이션 리소스")
                .font(.headline)

            if animations.isEmpty {
                Label("서버 클립 없음 · 기본 프레임 애니메이션으로 표시 중", systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(animations) { animation in
                    HStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(animation.title)
                                .font(.subheadline.bold())

                            Text(animation.durationSeconds.map { "\($0)초" } ?? "길이 미등록")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .appCard()
    }
}
