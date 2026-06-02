//
//  AppNavigationRow.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct NavigationRowItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
}

struct AppNavigationRow: View {
    let item: NavigationRowItem

    var body: some View {
        NavigationLink {
            PlaceholderDetailView(title: item.title, systemImage: item.systemImage)
        } label: {
            Label(item.title, systemImage: item.systemImage)
                .font(.body)
                .padding(.vertical, 6)
        }
    }
}

private struct PlaceholderDetailView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("This screen is ready for the next MVP step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
