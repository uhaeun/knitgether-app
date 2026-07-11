//
//  LibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @ObservedObject private var authSessionStore: AuthSessionStore
    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                patternRepository: repositories.patternRepository,
                libraryRepository: repositories.libraryRepository,
                skillRepository: repositories.skillRepository
            )
        )
        authSessionStore = repositories.authSessionStore
        patternRepository = repositories.patternRepository
        libraryRepository = repositories.libraryRepository
        skillRepository = repositories.skillRepository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let errorMessage = viewModel.errorMessage {
                    if viewModel.isEmpty {
                        OfflineFirstNoticeView(
                            title: "창고 데이터를 불러오지 못했어요.",
                            message: "계정 데이터를 불러오려면 서버 연결이 필요해요. 연결을 확인한 뒤 다시 시도해 주세요.",
                            detail: errorMessage,
                            systemImage: "externaldrive.badge.exclamationmark"
                        ) {
                            Task {
                                await viewModel.loadLibrary()
                            }
                        }
                    } else {
                        warningCard(errorMessage)
                    }
                }

                SectionHeaderView("내 창고")

                AppNavigationList {
                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "도안 창고",
                            subtitle: "\(viewModel.patterns.count)개 도안",
                            systemImage: "doc.text.fill",
                            tint: AppTheme.Color.accent
                        )
                    ) {
                        PatternLibraryView(patternRepository: patternRepository)
                    }

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "실 창고",
                            subtitle: "\(viewModel.yarns.count)개 실",
                            systemImage: "circle.hexagongrid.fill",
                            tint: AppTheme.Color.rose
                        )
                    ) {
                        YarnLibraryView(libraryRepository: libraryRepository)
                    }

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "바늘 창고",
                            subtitle: "\(viewModel.needles.count)개 바늘",
                            systemImage: "ruler.fill",
                            tint: AppTheme.Color.sage
                        )
                    ) {
                        NeedleLibraryView(libraryRepository: libraryRepository)
                    }

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "도구 창고",
                            subtitle: "\(viewModel.tools.count)개 도구",
                            systemImage: "wrench.and.screwdriver.fill",
                            tint: AppTheme.Color.amber
                        )
                    ) {
                        ToolLibraryView(libraryRepository: libraryRepository)
                    }

                    AppNavigationListRow(
                        item: NavigationRowItem(
                            title: "스킬 창고",
                            subtitle: "\(viewModel.skills.count)개 스킬",
                            systemImage: "graduationcap.fill",
                            tint: AppTheme.Color.lavender
                        ),
                        showsSeparator: false
                    ) {
                        SkillLibraryView(skillRepository: skillRepository)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .warmScreenBackground()
        .navigationTitle("창고")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadLibrary()
            }
        }
        .refreshable {
            await viewModel.loadLibrary()
        }
        .onReceive(authSessionStore.$currentSession.dropFirst()) { _ in
            Task {
                await viewModel.reloadAfterAccountChange()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("창고")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(AppTheme.Color.primaryText)

            Text("도안과 재료를 프로젝트에 바로 연결해요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func warningCard(_ message: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.Color.amber)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task {
                    await viewModel.loadLibrary()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("창고 다시 불러오기")
        }
        .padding()
        .appCard(cornerRadius: 20)
    }
}

#Preview {
    NavigationStack {
        LibraryView(repositories: .shared)
    }
}
