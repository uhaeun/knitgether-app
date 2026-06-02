//
//  LibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct LibraryView: View {
    private let rows = [
        NavigationRowItem(title: "Pattern Library", systemImage: "doc.text"),
        NavigationRowItem(title: "Yarn Library", systemImage: "circle.hexagongrid"),
        NavigationRowItem(title: "Needle Library", systemImage: "ruler"),
        NavigationRowItem(title: "Skill Library", systemImage: "graduationcap")
    ]

    var body: some View {
        List(rows) { row in
            AppNavigationRow(item: row)
        }
        .navigationTitle("Library")
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
