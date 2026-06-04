//
//  AppNavigationRow.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct NavigationRowItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemImage: String
}

struct AppNavigationRow<Destination: View>: View {
    let item: NavigationRowItem
    private let destination: Destination

    init(
        item: NavigationRowItem,
        @ViewBuilder destination: () -> Destination
    ) {
        self.item = item
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: item.systemImage)
            }
            .padding(.vertical, 6)
        }
    }
}
