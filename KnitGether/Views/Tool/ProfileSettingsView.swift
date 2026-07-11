//
//  ProfileSettingsView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var viewModel: ProfileSettingsViewModel
    @State private var isSaving = false

    init(profileRepository: any ProfileRepository) {
        _viewModel = StateObject(
            wrappedValue: ProfileSettingsViewModel(profileRepository: profileRepository)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let errorMessage = viewModel.errorMessage {
                    AppFormErrorBanner(message: errorMessage)
                }

                AppFormSection(
                    title: "프로필",
                    description: "앱 안에서 보일 이름을 설정해요.",
                    systemImage: "person.crop.circle",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormTextFieldRow(
                        title: "표시 이름",
                        placeholder: "이름",
                        systemImage: "person",
                        text: $viewModel.formData.displayName
                    )
                    .textInputAutocapitalization(.words)
                }

                AppFormSection(
                    title: "단위",
                    description: "게이지와 길이 입력에서 사용할 기본 단위예요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.sage
                ) {
                    Picker("기본 단위", selection: $viewModel.formData.preferredUnits) {
                        Text("Metric").tag("Metric")
                        Text("Imperial").tag("Imperial")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 12)
                }

                if let profile = viewModel.profile {
                    AppFormSection(
                        title: "계정 저장",
                        description: "서버 계정과 프로필 저장 상태를 확인해요.",
                        systemImage: "arrow.triangle.2.circlepath",
                        tint: AppTheme.Color.lavender
                    ) {
                        AppDetailInfoRow(title: "사용자 ID", value: profile.id, systemImage: "person.text.rectangle", tint: AppTheme.Color.lavender)

                        AppFormDivider()

                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "checkmark.icloud")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Color.lavender)
                                .frame(width: 22)

                            Text("상태")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Color.primaryText)

                            Spacer()

                            SyncStatusBadgeView(status: profile.syncStatus)
                        }
                        .padding(.vertical, 12)

                        Text(profile.syncStatus.detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 10)

                        if viewModel.hasProfileNeedingSync {
                            Button {
                                Task {
                                    await viewModel.retrySync()
                                }
                            } label: {
                                if viewModel.isRetryingSync {
                                    ProgressView()
                                } else {
                                    Label("다시 시도", systemImage: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isRetryingSync)
                        }

                        AppFormDivider()

                        AppDetailInfoRow(
                            title: "수정일",
                            value: profile.updatedAt.formatted(.dateTime.year().month().day()),
                            systemImage: "calendar",
                            tint: AppTheme.Color.lavender
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: isSaving || !viewModel.formData.canSave
            ) {
                Task {
                    isSaving = true
                    _ = await viewModel.saveProfile()
                    isSaving = false
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle("프로필 / 설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasProfileNeedingSync {
                    Button {
                        Task {
                            await viewModel.retrySync()
                        }
                    } label: {
                        if viewModel.isRetryingSync {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(viewModel.isRetryingSync)
                    .accessibilityLabel("프로필 저장 상태 다시 확인")
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .refreshable {
            await viewModel.loadProfile()
        }
    }

}

#Preview {
    NavigationStack {
        ProfileSettingsView(profileRepository: AppRepositoryContainer.shared.profileRepository)
    }
}
