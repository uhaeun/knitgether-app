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
                    title: "도안 창고",
                    subtitle: "\(viewModel.patterns.count)개 도안",
                    systemImage: "doc.text"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "도안 창고",
                    items: viewModel.patterns.map(\.title)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "실 창고",
                    subtitle: "\(viewModel.yarns.count)개 실",
                    systemImage: "circle.hexagongrid"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "실 창고",
                    items: viewModel.yarns.map(\.name)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "바늘 창고",
                    subtitle: "\(viewModel.needles.count)개 바늘",
                    systemImage: "ruler"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "바늘 창고",
                    items: viewModel.needles.map(\.name)
                )
            }

            AppNavigationRow(
                item: NavigationRowItem(
                    title: "스킬 창고",
                    subtitle: "\(viewModel.skills.count)개 스킬",
                    systemImage: "graduationcap"
                )
            ) {
                LibraryCollectionPlaceholderView(
                    title: "스킬 창고",
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
                Text("아직 등록된 항목이 없어요.")
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
