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
                mainTabs
                    .id(repositoryStore.container.instanceID)
            } else {
                OnboardingView(repositories: repositoryStore.container) {
                    onboardingCompleted = true
                }
            }
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
