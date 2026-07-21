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

    init(
        authRepository: any AuthRepository,
        sessionStore: AuthSessionStore
    ) {
        _viewModel = StateObject(
            wrappedValue: AuthAccountViewModel(
                authRepository: authRepository,
                sessionStore: sessionStore
            )
        )
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
                infoRow(title: "기본 단위", value: session.profile.preferredUnits, systemImage: "ruler")

                Text(session.profile.syncStatus.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .appCard(cornerRadius: 20)

            Button(role: .destructive) {
                do {
                    try viewModel.signOut()
                } catch {
                    // The stored session remains visible if secure storage fails to clear.
                }
            } label: {
                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier(AppAccessibilityID.Auth.logoutButton)
        }
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
                identifier: AppAccessibilityID.Auth.passwordField
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
                identifier: AppAccessibilityID.Auth.displayNameField
            )
            .textInputAutocapitalization(.words)

            fieldDivider

            HStack(spacing: 12) {
                Image(systemName: "ruler")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 28)

                Picker("기본 단위", selection: $viewModel.formData.preferredUnits) {
                    Text("Metric").tag("Metric")
                    Text("Imperial").tag("Imperial")
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 12)
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
        identifier: String
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
