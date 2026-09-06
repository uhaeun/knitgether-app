import SwiftUI

struct SettingsView: View {
    @ObservedObject private var authSessionStore: AuthSessionStore
    private let repositories: AppRepositoryContainer

    init(repositories: AppRepositoryContainer) {
        self.repositories = repositories
        authSessionStore = repositories.authSessionStore
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                profileCard

                settingsSection("학습 / 온보딩") {
                    AppNavigationList {
                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "스킬 테스트 다시 하기",
                                subtitle: "신호등 상태 갱신",
                                systemImage: "checklist",
                                tint: AppTheme.Color.sage
                            ),
                            showsSeparator: false
                        ) {
                            SkillTestView(skillRepository: repositories.skillRepository)
                        }
                    }
                }

                settingsSection("계정 / 프로필") {
                    AppNavigationList {
                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "계정 연동",
                                subtitle: "로그인 / 회원가입",
                                systemImage: "person.badge.key",
                                tint: AppTheme.Color.accent
                            )
                        ) {
                            AuthAccountView(
                                authRepository: repositories.authRepository,
                                sessionStore: repositories.authSessionStore,
                                repositories: repositories
                            )
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.accountCard)

                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "프로필 편집",
                                subtitle: "이름 / 단위",
                                systemImage: "person.crop.circle",
                                tint: AppTheme.Color.lavender
                            ),
                            showsSeparator: false
                        ) {
                            ProfileSettingsView(
                                profileRepository: repositories.profileRepository,
                                authSessionStore: repositories.authSessionStore,
                                requiresAuthenticatedProfile: repositories.profileRequiresAuthentication
                            )
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.profileCard)
                    }
                }

                settingsSection("통계") {
                    AppNavigationList {
                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "작업시간 통계",
                                subtitle: "세션 / 프로젝트별",
                                systemImage: "chart.bar.fill",
                                tint: AppTheme.Color.rose
                            )
                        ) {
                            WorkTimeStatisticsView(projectRepository: repositories.projectRepository)
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.statisticsCard)

                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "작업 세션 목록",
                                subtitle: "메모 / 수정 / 삭제",
                                systemImage: "clock.arrow.circlepath",
                                tint: AppTheme.Color.lavender
                            ),
                            showsSeparator: false
                        ) {
                            WorkSessionListView(projectRepository: repositories.projectRepository)
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.workSessionsCard)
                    }
                }

                settingsSection("데이터") {
                    AppNavigationList {
                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "데이터 백업",
                                subtitle: "JSON 내보내기 / 가져오기",
                                systemImage: "externaldrive.badge.icloud",
                                tint: AppTheme.Color.amber
                            )
                        ) {
                            DataBackupView(
                                sessionStore: repositories.authSessionStore,
                                profileRepository: repositories.profileRepository,
                                projectRepository: repositories.projectRepository,
                                patternRepository: repositories.patternRepository,
                                libraryRepository: repositories.libraryRepository,
                                skillRepository: repositories.skillRepository,
                                dictionaryRepository: repositories.dictionaryRepository,
                                gaugeRecordRepository: repositories.gaugeRecordRepository,
                                progressPhotoRepository: repositories.progressPhotoRepository
                            )
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.backupCard)

                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "데이터 관리",
                                subtitle: "저장 개수 확인",
                                systemImage: "folder.badge.gearshape",
                                tint: AppTheme.Color.slate
                            ),
                            showsSeparator: false
                        ) {
                            DataManagementView(
                                projectRepository: repositories.projectRepository,
                                patternRepository: repositories.patternRepository,
                                libraryRepository: repositories.libraryRepository,
                                skillRepository: repositories.skillRepository,
                                dictionaryRepository: repositories.dictionaryRepository,
                                gaugeRecordRepository: repositories.gaugeRecordRepository,
                                progressPhotoRepository: repositories.progressPhotoRepository
                            )
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Settings.dataManagementCard)
                    }
                }

                settingsSection("앱 정보") {
                    AppNavigationList {
                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "뜨개 상태 설명",
                                subtitle: "CO / WIP / UFO / FO",
                                systemImage: "list.bullet.rectangle",
                                tint: AppTheme.Color.sage
                            )
                        ) {
                            ProjectStatusGuideView()
                        }

                        AppNavigationListRow(
                            item: NavigationRowItem(
                                title: "앱 정보",
                                subtitle: "버전 / 저장 구조",
                                systemImage: "info.circle",
                                tint: AppTheme.Color.accent
                            ),
                            showsSeparator: false
                        ) {
                            AppInfoView()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .warmScreenBackground()
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("설정")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(AppTheme.Color.primaryText)

            Text("계정, 데이터, 작업 기록을 관리해요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileCard: some View {
        NavigationLink {
            ProfileSettingsView(
                profileRepository: repositories.profileRepository,
                authSessionStore: repositories.authSessionStore,
                requiresAuthenticatedProfile: repositories.profileRequiresAuthentication
            )
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.Color.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.Color.primaryText)

                    Text(accountStateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .appCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        authSessionStore.currentSession?.profile.displayName ?? "뜨개러"
    }

    private var accountStateText: String {
        if let session = authSessionStore.currentSession {
            return "서버 계정 연결됨 · \(session.profile.ownerId ?? session.profile.id)"
        }
        return "로컬 캐시로 사용 중"
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(title)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(repositories: .shared)
    }
}
