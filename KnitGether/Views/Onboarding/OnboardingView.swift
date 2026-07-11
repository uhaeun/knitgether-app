//
//  OnboardingView.swift
//  KnitGether
//
//  Created by Codex on 7/10/26.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    private let repositories: AppRepositoryContainer
    private let onComplete: () -> Void

    init(
        repositories: AppRepositoryContainer,
        onComplete: @escaping () -> Void
    ) {
        self.repositories = repositories
        _viewModel = StateObject(
            wrappedValue: OnboardingViewModel(
                profileRepository: repositories.profileRepository
            )
        )
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 28) {
                        currentStepView
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }

                footer
            }
            .warmScreenBackground()
            .navigationBarHidden(true)
            .task {
                await viewModel.loadExistingProfileIfAvailable()
            }
            .onChange(of: repositories.instanceID) { _ in
                viewModel.replaceProfileRepository(repositories.profileRepository)
                Task {
                    await viewModel.loadExistingProfileIfAvailable()
                }
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(Array(OnboardingViewModel.Step.allCases.enumerated()), id: \.offset) { index, _ in
                Capsule()
                    .fill(index <= viewModel.currentStep.rawValue ? AppTheme.Color.accent : AppTheme.Color.warmDivider)
                    .frame(width: index == viewModel.currentStep.rawValue ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.35), value: viewModel.currentStep)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .intro:
            introStep
        case .account:
            accountStep
        case .profile:
            profileStep
        case .preferences:
            preferencesStep
        case .skillTest:
            skillTestStep
        case .ready:
            readyStep
        }
    }

    private var introStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 74))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 124, height: 124)
                .background(AppTheme.Color.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))

            VStack(spacing: 8) {
                Text("KnitGether")
                    .font(.largeTitle.bold())

                Text("프로젝트와 작업 기록을 준비합니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                systemImage: "person.crop.circle",
                title: "프로필",
                subtitle: "앱에서 사용할 이름"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("이름")
                    .font(.subheadline.weight(.semibold))

                TextField("뜨개러", text: $viewModel.formData.displayName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                systemImage: "person.badge.key",
                title: "계정",
                subtitle: "계정 저장 연결"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("회원가입하거나 로그인하면 프로젝트, 창고, 스킬 상태를 내 계정에 저장할 수 있어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    AuthAccountView(
                        authRepository: repositories.authRepository,
                        sessionStore: repositories.authSessionStore
                    )
                } label: {
                    Label("계정 만들기 / 로그인", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier(AppAccessibilityID.Onboarding.loginButton)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .appCard()
        }
    }

    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                systemImage: "ruler",
                title: "단위",
                subtitle: "게이지와 치수 입력 기준"
            )

            Picker("단위", selection: $viewModel.formData.preferredUnits) {
                ForEach(viewModel.unitOptions, id: \.self) { unit in
                    Text(unit).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var skillTestStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                systemImage: "checklist",
                title: "스킬 테스트",
                subtitle: "모름, 헷갈림, 앎을 신호등으로 표시"
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("각 스킬을 얼마나 알고 있는지 표시하면 행안내, 뜨개니게이션, 애니메이션 목록에서 빨강/주황/초록 상태로 확인할 수 있어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    ForEach(SkillLevelFormatter.levels, id: \.self) { level in
                        SkillLevelBadgeView(level: level)
                    }
                }

                NavigationLink {
                    SkillTestView(skillRepository: repositories.skillRepository)
                } label: {
                    Label("스킬 테스트 시작", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier(AppAccessibilityID.Onboarding.startButton)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .appCard()
        }
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 62))
                .foregroundStyle(AppTheme.Color.sage)
                .frame(width: 112, height: 112)
                .background(AppTheme.Color.sageSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))

            VStack(spacing: 8) {
                Text("\(viewModel.formData.normalizedDisplayName)님")
                    .font(.title.bold())

                Text("준비가 끝났어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stepHeader(
        systemImage: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 46, height: 46)
                .background(AppTheme.Color.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("이전")
            }

            Button {
                handlePrimaryAction()
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(primaryButtonTitle, systemImage: viewModel.isLastStep ? "checkmark" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier(viewModel.isLastStep ? AppAccessibilityID.Onboarding.completeButton : AppAccessibilityID.Onboarding.startButton)
            .disabled(viewModel.isSaving)
        }
        .padding(16)
        .background(.bar)
    }

    private var primaryButtonTitle: String {
        viewModel.isLastStep ? "시작" : "다음"
    }

    private func handlePrimaryAction() {
        if viewModel.isLastStep {
            Task {
                let didComplete = await viewModel.completeOnboarding()

                if didComplete {
                    onComplete()
                }
            }
        } else {
            viewModel.goNext()
        }
    }
}

#Preview {
    OnboardingView(repositories: .shared) {
    }
}
