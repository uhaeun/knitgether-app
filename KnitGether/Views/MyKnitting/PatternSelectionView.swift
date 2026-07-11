//
//  PatternSelectionView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct PatternSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let patterns: [PatternDocument]
    let onSelect: (PatternDocument) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if patterns.isEmpty {
                    emptyState
                } else {
                    List(patterns) { pattern in
                        Button {
                            onSelect(pattern)
                            dismiss()
                        } label: {
                            PatternSelectionRow(pattern: pattern)
                        }
                        .buttonStyle(.plain)
                        .listRowStyle()
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Color.warmBackground)
                }
            }
            .warmScreenBackground()
            .navigationTitle("Library에서 가져오기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "도안 창고에 등록된 도안이 없어요.",
            description: "Library의 도안 창고에서 PDF 도안을 먼저 추가해 주세요.",
            systemImage: "books.vertical"
        )
        .padding()
    }
}

private struct PatternSelectionRow: View {
    let pattern: PatternDocument

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.accentSoft)

                Image(systemName: "doc.richtext")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Color.accent)
            }
            .frame(width: 44, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(pattern.fileName ?? "파일 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.Color.accent.opacity(0.55))
        }
        .padding(12)
        .appCard()
    }
}

#Preview {
    PatternSelectionView(patterns: SampleData.patternDocuments) { _ in }
}
