//
//  ToolsView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct ToolsView: View {
    private let rows = [
        NavigationRowItem(title: "Gauge Calculator", systemImage: "function"),
        NavigationRowItem(title: "Knitting Animations", systemImage: "play.rectangle"),
        NavigationRowItem(title: "Knitting Dictionary", systemImage: "text.book.closed")
    ]

    var body: some View {
        List(rows) { row in
            AppNavigationRow(item: row)
        }
        .navigationTitle("Tools")
    }
}

#Preview {
    NavigationStack {
        ToolsView()
    }
}
