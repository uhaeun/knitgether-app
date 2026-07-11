//
//  WorkspaceSectionView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct WorkspaceSectionView<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.Color.primaryText)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .appCard(cornerRadius: 20)
    }
}
