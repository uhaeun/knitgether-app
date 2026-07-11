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
    var description: String? = nil
    let systemImage: String
    var tint: Color = AppTheme.Color.accent
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

struct AppNavigationCard<Destination: View>: View {
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
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .frame(width: 36, height: 36)
                    .background(item.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Color.primaryText)
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary.opacity(0.55))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .appCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct AppNavigationList<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(AppTheme.Color.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .shadow(
            color: Color.black.opacity(AppTheme.Card.shadowOpacity),
            radius: AppTheme.Card.shadowRadius,
            x: 0,
            y: AppTheme.Card.shadowY
        )
    }
}

struct AppNavigationListRow<Destination: View>: View {
    let item: NavigationRowItem
    var showsSeparator: Bool = true
    private let destination: Destination

    init(
        item: NavigationRowItem,
        showsSeparator: Bool = true,
        @ViewBuilder destination: () -> Destination
    ) {
        self.item = item
        self.showsSeparator = showsSeparator
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.tint)
                        .frame(width: 36, height: 36)
                        .background(item.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.Color.primaryText)
                            .lineLimit(1)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary.opacity(0.55))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .contentShape(Rectangle())

                if showsSeparator {
                    Rectangle()
                        .fill(AppTheme.Color.warmDivider)
                        .frame(height: 1)
                        .padding(.leading, 63)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
