//
//  ContentView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.onboardingCompleted) private var onboardingCompleted = false
    @StateObject private var repositoryStore: AppRepositoryStore
    @ObservedObject private var authSessionStore = AuthSessionStore.shared

    @MainActor
    init() {
        _repositoryStore = StateObject(wrappedValue: AppRepositoryStore())
    }

    @MainActor
    init(repositoryStore: AppRepositoryStore) {
        _repositoryStore = StateObject(wrappedValue: repositoryStore)
    }

    var body: some View {
        Group {
            if onboardingCompleted {
                // AUTH-06: 인증이 요구되는 환경(원격 모드, 정적 토큰 없음)에서 세션이 없으면
                // 로컬 캐시를 노출하지 않고 로그인 화면으로 유도한다.
                // 시뮬레이터/개발 환경(정적 토큰 주입)은 profileRequiresAuthentication이
                // false라 기존 흐름이 유지된다.
                if repositoryStore.container.profileRequiresAuthentication,
                   authSessionStore.currentSession == nil {
                    signInGate
                } else {
                    mainTabs
                        .id(repositoryStore.container.instanceID)
                }
            } else {
                OnboardingView(repositories: repositoryStore.container) {
                    onboardingCompleted = true
                }
            }
        }
    }

    private var signInGate: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("로그인이 필요해요")
                        .font(.title2.bold())

                    Text("계정으로 로그인하면 이 기기의 뜨개 기록을 안전하게 이어서 볼 수 있어요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                AuthAccountView(
                    authRepository: repositoryStore.container.authRepository,
                    sessionStore: authSessionStore
                )
            }
            .warmScreenBackground()
        }
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                HomeView(repositories: repositoryStore.container)
            }
            .accessibilityIdentifier(AppAccessibilityID.Tab.home)
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }

            NavigationStack {
                MyKnittingView(repositories: repositoryStore.container)
            }
            .accessibilityIdentifier(AppAccessibilityID.Tab.myKnitting)
            .tabItem {
                Label("내 뜨개", systemImage: "heart.text.square.fill")
            }

            NavigationStack {
                LibraryView(repositories: repositoryStore.container)
            }
            .accessibilityIdentifier(AppAccessibilityID.Tab.library)
            .tabItem {
                Label("창고", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                ToolView(repositories: repositoryStore.container)
            }
            .accessibilityIdentifier(AppAccessibilityID.Tab.tool)
            .tabItem {
                Label("도구", systemImage: "wrench.and.screwdriver.fill")
            }

            NavigationStack {
                SettingsView(repositories: repositoryStore.container)
            }
            .accessibilityIdentifier(AppAccessibilityID.Tab.settings)
            .tabItem {
                Label("설정", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.Color.accent)
    }
}

#Preview {
    ContentView()
}
