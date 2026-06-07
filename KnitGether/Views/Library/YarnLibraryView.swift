//
//  YarnLibraryView.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import SwiftUI

struct YarnLibraryView: View {
    @StateObject private var viewModel: YarnLibraryViewModel
    @State private var isShowingAddYarn = false
    @State private var yarnPendingDeletion: Yarn?
    @State private var isShowingDeleteConfirmation = false

    init(libraryRepository: any LibraryRepository) {
        _viewModel = StateObject(
            wrappedValue: YarnLibraryViewModel(libraryRepository: libraryRepository)
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if viewModel.yarns.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.yarns) { yarn in
                    NavigationLink {
                        YarnFormView(
                            title: "실 수정",
                            formData: YarnFormData(yarn: yarn),
                            showsDeleteButton: true,
                            onSave: { formData in
                                await viewModel.updateYarn(yarn, with: formData)
                            },
                            onDelete: {
                                await viewModel.deleteYarn(yarn)
                            }
                        )
                    } label: {
                        YarnRowView(yarn: yarn)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("삭제", role: .destructive) {
                            yarnPendingDeletion = yarn
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .navigationTitle("실 창고")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddYarn = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("실 추가")
            }
        }
        .sheet(isPresented: $isShowingAddYarn) {
            NavigationStack {
                YarnFormView(title: "실 추가") { formData in
                    await viewModel.addYarn(from: formData)
                }
            }
        }
        .alert("실을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: yarnPendingDeletion) { yarn in
            Button("취소", role: .cancel) {
                yarnPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteYarn(yarn)
                    yarnPendingDeletion = nil
                }
            }
        } message: { _ in
            Text("삭제한 실 정보는 복구할 수 없어요.")
        }
        .task {
            await viewModel.loadYarns()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아직 등록된 실이 없어요.")
                .font(.headline)

            Text("사용하는 실을 추가해 보세요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                isShowingAddYarn = true
            } label: {
                Label("실 추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.vertical, 12)
    }
}

private struct YarnRowView: View {
    let yarn: Yarn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(yarn.name)
                .font(.headline)

            HStack(spacing: 8) {
                if let brand = yarn.brand {
                    Text(brand)
                }

                if let colorName = yarn.colorName {
                    Text("색상 \(colorName)")
                }

                if let quantity = yarn.quantity {
                    Text("보유 수량 \(quantity)")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let memo = yarn.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        YarnLibraryView(libraryRepository: AppRepositoryContainer.shared.libraryRepository)
    }
}
