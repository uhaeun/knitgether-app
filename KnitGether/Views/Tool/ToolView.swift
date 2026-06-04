//
//  ToolView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ToolView: View {
    private let rows = [
        NavigationRowItem(title: "게이지 계산기", subtitle: "코와 단수를 계산합니다", systemImage: "function"),
        NavigationRowItem(title: "뜨개 사전", subtitle: "뜨개 용어를 찾아봅니다", systemImage: "text.book.closed"),
        NavigationRowItem(title: "뜨개 애니메이션", subtitle: "스킬 동작을 확인합니다", systemImage: "play.rectangle")
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

            Text("다음 단계에서 로컬 도구 기능이 추가됩니다.")
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
