import SwiftUI

struct SkillTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SkillTestViewModel
    @State private var isShowingSkipAlert = false

    private let skillRepository: any SkillRepository

    init(skillRepository: any SkillRepository) {
        self.skillRepository = skillRepository
        _viewModel = StateObject(
            wrappedValue: SkillTestViewModel(skillRepository: skillRepository)
        )
    }

    var body: some View {
        Group {
            if viewModel.isCompleted, let summary = viewModel.resultSummary {
                SkillTestResultView(
                    summary: summary,
                    skillRepository: skillRepository
                ) {
                    dismiss()
                }
            } else if viewModel.skills.isEmpty {
                emptyState
            } else {
                testContent
            }
        }
        .warmScreenBackground()
        .navigationTitle("스킬 테스트")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSkills()
        }
        .alert("스킬 테스트를 나중에 할까요?", isPresented: $isShowingSkipAlert) {
            Button("저장하고 나가기") {
                Task {
                    let didSave = await viewModel.savePartialAndExit()
                    if didSave {
                        dismiss()
                    }
                }
            }

            Button("저장하지 않고 나가기", role: .destructive) {
                dismiss()
            }

            Button("계속하기", role: .cancel) {}
        } message: {
            Text("지금까지 선택한 내용은 저장하고 나갈 수 있어요.")
        }
        .alert("오류", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var testContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("각 스킬을 얼마나 알고 있는지 선택해주세요.")
                        .font(.title3.bold())

                    Text("선택한 상태는 행안내와 학습 목록에서 함께 쓰입니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .appCard()

                SkillTestProgressView(
                    progressText: viewModel.progressText,
                    progressValue: viewModel.progressValue
                )

                if let currentSkill = viewModel.currentSkill {
                    SkillTestCardView(
                        skill: currentSkill,
                        selectedLevel: viewModel.selectedLevel(for: currentSkill),
                        levelOptions: viewModel.levelOptions
                    ) { level in
                        viewModel.selectLevel(level, for: currentSkill)
                    }
                }

                navigationControls
            }
            .padding()
        }
        .warmScreenBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("나중에 하기") {
                    isShowingSkipAlert = true
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "테스트할 스킬이 없어요.",
            description: "스킬 창고에 스킬을 추가하거나 서버 저장 상태를 다시 확인해 주세요.",
            systemImage: "checklist",
            action: {
                Task {
                    await viewModel.loadSkills()
                }
            }
        ) {
            Label("다시 불러오기", systemImage: "arrow.clockwise")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }

    private var navigationControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    viewModel.goPrevious()
                } label: {
                    Label("이전", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canGoPrevious)

                if viewModel.isLastSkill {
                    Button {
                        Task {
                            await viewModel.saveResults()
                        }
                    } label: {
                        Label("완료", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        viewModel.goNext()
                    } label: {
                        Label("다음", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Button("나중에 하기", role: .destructive) {
                isShowingSkipAlert = true
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        SkillTestView(skillRepository: AppRepositoryContainer.shared.skillRepository)
    }
}
