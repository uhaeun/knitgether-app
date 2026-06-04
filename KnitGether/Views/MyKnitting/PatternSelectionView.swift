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
                    }
                }
            }
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
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("도안 창고에 등록된 도안이 없어요.")
                .font(.headline)

            Text("Library의 도안 창고에서 PDF 도안을 먼저 추가해 주세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct PatternSelectionRow: View {
    let pattern: PatternDocument

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))

                Image(systemName: "doc.richtext")
                    .font(.title3)
                    .foregroundStyle(.secondary)
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PatternSelectionView(patterns: SampleData.patternDocuments) { _ in }
}
