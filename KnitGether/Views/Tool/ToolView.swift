//
//  ToolView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ToolView: View {
    private let rows = [
        NavigationRowItem(title: "Gauge Calculator", subtitle: "Calculate stitches and rows", systemImage: "function"),
        NavigationRowItem(title: "Knitting Dictionary", subtitle: "Look up stitch terms", systemImage: "text.book.closed"),
        NavigationRowItem(title: "Knitting Animations", subtitle: "Open local skill demos", systemImage: "play.rectangle")
    ]

    var body: some View {
        List(rows) { row in
            AppNavigationRow(item: row) {
                ToolPlaceholderView(title: row.title, systemImage: row.systemImage)
            }
        }
        .navigationTitle("Tool")
    }
}

private struct ToolPlaceholderView: View {
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

            Text("Local tool implementation will be added in the next layer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ToolView()
    }
}
