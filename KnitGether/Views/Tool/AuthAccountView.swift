//
//  AuthAccountView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct AuthAccountView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case login = "로그인"
        case register = "회원가입"

        var id: String { rawValue }
    }

    @StateObject private var viewModel: AuthAccountViewModel
    @State private var mode: Mode = .login
    @State private var isSubmitting = false
    @State private var isShowingSignOutFailureAlert = false
    @State private var isSigningOut = false
    @State private var unsyncedCountBeforeSignOut = 0
    @State private var isShowingUnsyncedSignOutConfirmation = false

    /// 로그아웃 시 미동기화 항목을 올리고 계정 로컬 저장소를 지우는 데 쓴다.
    /// 온보딩처럼 아직 컨테이너를 넘길 수 없는 자리에서는 nil이고, 그때는 캐시 삭제를 건너뛴다.
    private let repositories: AppRepositoryContainer?

    init(
        authRepository: any AuthRepository,
        sessionStore: AuthSessionStore,
        repositories: AppRepositoryContainer? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: AuthAccountViewModel(
                authRepository: authRepository,
                sessionStore: sessionStore
            )
        )
        self.repositories = repositories
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let statusMessage = viewModel.statusMessage {
                    AppFormStatusBanner(message: statusMessage)
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }

                if let session = viewModel.currentSession {
                    signedInContent(session: session)
                } else {
                    signedOutContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.currentSession == nil {
                submitBar
            }
        }
        .navigationTitle("계정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasAccountRefreshError {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.retryLoadSession()
                        }
                    } label: {
                        if viewModel.isRefreshingAccount {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(viewModel.isRefreshingAccount)
                    .accessibilityLabel("계정 정보 다시 시도")
                }
            }
        }
        .warmScreenBackground()
        .task {
            await viewModel.loadSession()
        }
        .refreshable {
            await viewModel.loadSession()
        }
    }

    private var signedOutContent: some View {
        VStack(spacing: 24) {
            brandHeader
            modePicker
            credentialCard

            if mode == .register {
                profileCard
            }
        }
    }

    private func signedInContent(session: AuthSession) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            brandHeader

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 54, height: 54)
                        .background(AppTheme.Color.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.profile.displayName)
                            .font(.headline)
                            .foregroundStyle(AppTheme.Color.primaryText)

                        if let currentUser = viewModel.currentUser {
                            Text(currentUser.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("계정 정보를 불러오는 중")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    SyncStatusBadgeView(status: session.profile.syncStatus)
                }

                Divider()
                    .overlay(AppTheme.Color.warmDivider)

                infoRow(title: "사용자 ID", value: session.profile.id, systemImage: "person.text.rectangle")

                Text(session.profile.syncStatus.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .appCard(cornerRadius: 20)

            Button(role: .destructive) {
                startSignOut()
            } label: {
                Label(isSigningOut ? "정리하는 중" : "로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isSigningOut)
            .accessibilityIdentifier(AppAccessibilityID.Auth.logoutButton)
            .alert("로그아웃하지 못했어요", isPresented: $isShowingSignOutFailureAlert) {
                Button("다시 시도") {
                    startSignOut()
                }

                Button("닫기", role: .cancel) {}
            } message: {
                Text("저장된 로그인 정보를 삭제하지 못해 로그인 세션이 아직 남아 있어요. 잠시 후 다시 시도해 주세요.")
            }
            .alert("올리지 못한 작업이 있어요", isPresented: $isShowingUnsyncedSignOutConfirmation) {
                Button("그래도 로그아웃", role: .destructive) {
                    finishSignOut()
                }

                Button("취소", role: .cancel) {}
            } message: {
                Text("이 기기에만 있는 작업 \(unsyncedCountBeforeSignOut)개를 서버에 올리지 못했어요. 지금 로그아웃하면 그 작업은 사라져요. 네트워크를 확인하고 잠시 후 다시 시도할 수 있어요.")
            }
        }
    }

    /// 로그아웃 절차. 지우기 전에 올린다.
    ///
    /// 계정 로컬 저장소에는 서버에서 받아온 항목과 아직 올리지 못한 항목이 함께 있다.
    /// 그냥 지우면 계정 노출(DEF-05~07)은 닫히지만 사용자가 만든 작업이 무통보로 사라진다.
    /// 올릴 수 있는 것을 먼저 올리고, 그러고도 남는 것이 있으면 사용자에게 개수를 알린다.
    private func startSignOut() {
        guard !isSigningOut else {
            return
        }

        isSigningOut = true
        Task {
            let remaining = await repositories?.flushPendingChanges() ?? 0
            unsyncedCountBeforeSignOut = remaining

            if remaining > 0 {
                isSigningOut = false
                isShowingUnsyncedSignOutConfirmation = true
                return
            }

            finishSignOut()
        }
    }

    /// Keychain 삭제 실패를 무통보로 삼키지 않는다. 세션이 남아 있음을 알리고 재시도를 제공한다.
    /// 캐시 삭제는 세션을 지우기 전에 소유자 id를 읽어야 하므로 순서를 지킨다.
    private func finishSignOut() {
        let ownerId = viewModel.currentSession.map { $0.profile.ownerId ?? $0.profile.id }

        do {
            try viewModel.signOut()
            AppRepositoryContainer.removeCachedData(for: ownerId)
        } catch {
            isShowingSignOutFailureAlert = true
        }

        isSigningOut = false
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.Color.softAccent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                }

            VStack(spacing: 4) {
                Text("뜨개더")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.Color.primaryText)

                Text("뜨개를 기록하는 가장 쉬운 방법")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == item ? AppTheme.Color.primaryText : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if mode == item {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.Color.knitTexture, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier(AppAccessibilityID.Auth.modePicker)
    }

    private var credentialCard: some View {
        VStack(spacing: 0) {
            authField(
                title: "이메일",
                systemImage: "envelope",
                text: $viewModel.formData.email,
                isSecure: false,
                identifier: AppAccessibilityID.Auth.emailField
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            fieldDivider

            authField(
                title: "비밀번호",
                systemImage: "lock",
                text: $viewModel.formData.password,
                isSecure: true,
                identifier: AppAccessibilityID.Auth.passwordField,
                characterLimit: AppInputLimit.password
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .appCard(cornerRadius: 18)
    }

    private var profileCard: some View {
        VStack(spacing: 0) {
            authField(
                title: "표시 이름",
                systemImage: "person",
                text: $viewModel.formData.displayName,
                isSecure: false,
                identifier: AppAccessibilityID.Auth.displayNameField,
                characterLimit: AppInputLimit.displayName
            )
            .textInputAutocapitalization(.words)

            fieldDivider

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .appCard(cornerRadius: 18)
    }

    private func authField(
        title: String,
        systemImage: String,
        text: Binding<String>,
        isSecure: Bool,
        identifier: String,
        characterLimit: Int? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 28)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                }
            }
            .font(.body)
            .foregroundStyle(AppTheme.Color.primaryText)
            .accessibilityIdentifier(identifier)
            // 타이핑이든 붙여넣기든 상한을 넘는 입력은 잘라낸다 (SPEC-PROJ-01과 같은 UX)
            .onChange(of: text.wrappedValue) { newValue in
                if let characterLimit, newValue.count > characterLimit {
                    text.wrappedValue = String(newValue.prefix(characterLimit))
                }
            }

            if let characterLimit {
                Text("\(text.wrappedValue.count)/\(characterLimit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 16)
    }

    private var fieldDivider: some View {
        Rectangle()
            .fill(AppTheme.Color.warmDivider)
            .frame(height: 1)
            .padding(.leading, 40)
    }

    private var submitBar: some View {
        VStack(spacing: 0) {
            Button {
                Task {
                    await submit()
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(mode.rawValue)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(canSubmit ? AppTheme.Color.softAccent : AppTheme.Color.softAccent.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(isSubmitting || !canSubmit)
            .accessibilityIdentifier(AppAccessibilityID.Auth.submitButton)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func infoRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.Color.amber)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.Color.primaryText)

            Spacer()

            if viewModel.hasAccountRefreshError {
                Button {
                    Task {
                        await viewModel.retryLoadSession()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isRefreshingAccount)
            }
        }
        .padding(14)
        .background(AppTheme.Color.amberSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var canSubmit: Bool {
        switch mode {
        case .login:
            viewModel.formData.canLogin
        case .register:
            viewModel.formData.canRegister
        }
    }

    private func submit() async {
        isSubmitting = true
        switch mode {
        case .login:
            _ = await viewModel.login()
        case .register:
            _ = await viewModel.register()
        }
        isSubmitting = false
    }
}

#Preview {
    NavigationStack {
        AuthAccountView(
            authRepository: AppRepositoryContainer.shared.authRepository,
            sessionStore: AppRepositoryContainer.shared.authSessionStore
        )
    }
}
