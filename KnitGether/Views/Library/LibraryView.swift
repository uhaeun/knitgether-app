//
//  LibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(repositories: AppRepositoryContainer) {
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                patternRepository: repositories.patternRepository,
                libraryRepository: repositories.libraryRepository,
                skillRepository: repositories.skillRepository
            )
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "Pattern Library",
                    subtitle: "\(viewModel.patterns.count) patterns",
                    systemImage: "doc.text"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "Pattern Library",
                    items: viewModel.patterns.map(\.title)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "Yarn Library",
                    subtitle: "\(viewModel.yarns.count) yarns",
                    systemImage: "circle.hexagongrid"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "Yarn Library",
                    items: viewModel.yarns.map(\.name)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "Needle Library",
                    subtitle: "\(viewModel.needles.count) needles",
                    systemImage: "ruler"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "Needle Library",
                    items: viewModel.needles.map(\.name)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "Skill Library",
                    subtitle: "\(viewModel.skills.count) skills",
                    systemImage: "graduationcap"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "Skill Library",
                    items: viewModel.skills.map(\.title)
                )
            }
        }
        .navigationTitle("Library")
        .task {
            await viewModel.loadLibrary()
        }
    }
}

private struct LibraryCollectionPlaceholderView: View {
    let title: String
    let items: [String]

    var body: some View {
        List {
            if items.isEmpty {
                Text("No local sample items yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LibraryView(repositories: .shared)
    }
}
