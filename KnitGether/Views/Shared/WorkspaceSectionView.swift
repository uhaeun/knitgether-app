//
//  WorkspaceSectionView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct WorkspaceSectionView<Content: View, HeaderAction: View>: View {
    let title: String
    let systemImage: String
    private let headerAction: HeaderAction
    private let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder headerAction: () -> HeaderAction,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.headerAction = headerAction()
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

                Spacer(minLength: 8)

                headerAction
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .appCard(cornerRadius: 20)
    }
}

extension WorkspaceSectionView where HeaderAction == EmptyView {
    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, systemImage: systemImage, headerAction: { EmptyView() }, content: content)
    }
}

/// 패널 헤더에 놓는 아이콘 버튼. 저장, 연결처럼 그 패널의 주요 동작 하나를 담는다.
struct WorkspaceHeaderActionButton: View {
    let systemImage: String
    let label: String
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isProminent ? Color.white : AppTheme.Color.accent)
                .frame(width: 32, height: 32)
                .background(
                    isProminent ? AnyShapeStyle(AppTheme.Color.accent) : AnyShapeStyle(AppTheme.Color.accentSoft),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
