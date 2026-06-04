//
//  PatternLibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PatternLibraryView: View {
    @StateObject private var viewModel: PatternLibraryViewModel
    @State private var isShowingFileImporter = false
    @State private var patternPendingDeletion: PatternDocument?
    @State private var isShowingDeleteConfirmation = false

    init(patternRepository: any PatternRepository) {
        _viewModel = StateObject(
            wrappedValue: PatternLibraryViewModel(patternRepository: patternRepository)
        )
    }

    var body: some View {
        Group {
            if viewModel.patterns.isEmpty {
                emptyState
            } else {
                patternList
            }
        }
        .navigationTitle("도안 창고")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingFileImporter = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("추가")
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporterResult(result)
        }
        .alert("도안을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: patternPendingDeletion) { pattern in
            Button("취소", role: .cancel) {
                patternPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deletePattern(pattern)
                    patternPendingDeletion = nil
                }
            }
        } message: { _ in
            Text("Library 원본만 삭제돼요. 프로젝트에 가져온 도안 사본은 유지돼요.")
        }
        .task {
            await viewModel.loadPatterns()
        }
    }

    private var patternList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.patterns) { pattern in
                PatternLibraryRow(pattern: pattern)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            patternPendingDeletion = pattern
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("아직 등록된 도안이 없어요.")
                .font(.title3)
                .fontWeight(.semibold)

            Text("PDF 도안을 추가해 Library에서 관리할 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                isShowingFileImporter = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let fileURLs):
            guard let fileURL = fileURLs.first else {
                return
            }

            Task {
                await viewModel.addPattern(fromFileAt: fileURL)
            }
        case .failure:
            break
        }
    }
}

private struct PatternLibraryRow: View {
    let pattern: PatternDocument

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))

                Image(systemName: "doc.richtext")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(pattern.fileName ?? "파일 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("등록일 \(formattedDate(pattern.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !pattern.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(pattern.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day())
    }
}

#Preview {
    NavigationStack {
        PatternLibraryView(patternRepository: AppRepositoryContainer.shared.patternRepository)
    }
}
