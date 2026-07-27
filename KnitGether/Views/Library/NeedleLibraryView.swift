//
//  NeedleLibraryView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct NeedleLibraryView: View {
    @StateObject private var viewModel: NeedleLibraryViewModel
    @State private var isShowingAddNeedle = false
    @State private var needlePendingDetail: Needle?
    @State private var needlePendingDeletion: Needle?
    @State private var isShowingDeleteConfirmation = false

    init(libraryRepository: any LibraryRepository) {
        _viewModel = StateObject(
            wrappedValue: NeedleLibraryViewModel(libraryRepository: libraryRepository)
        )
    }

    var body: some View {
        Group {
            if viewModel.needles.isEmpty {
                emptyState
            } else {
                needleList
            }
        }
        .navigationTitle("바늘 창고")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "바늘 이름, 종류, 사이즈 검색"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasNeedlesNeedingSync {
                    Button {
                        Task {
                            await viewModel.retrySync()
                        }
                    } label: {
                        if viewModel.isRetryingSync {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(viewModel.isRetryingSync)
                    .accessibilityLabel("바늘 창고 저장 상태 다시 확인")
                }

                Button {
                    isShowingAddNeedle = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Library.needleAddButton)
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddNeedle) {
            NeedleFormView(title: "바늘 추가") { formData in
                await viewModel.addNeedle(from: formData)
            }
        }
        .sheet(item: $needlePendingDetail) { needle in
            NeedleDetailView(
                needle: needle,
                detailRows: NeedleLibraryViewModel.detailRows(for: needle)
            ) { formData in
                await viewModel.updateNeedle(needle, from: formData)
            } onDelete: {
                await viewModel.deleteNeedle(needle)
            }
        }
        .alert("바늘을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: needlePendingDeletion) { needle in
            Button("취소", role: .cancel) {
                needlePendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteNeedle(needle)
                    let selectedDetailID = LibraryDeletionPresentation.selectedDetailID(
                        afterDeleting: needle.id,
                        didDelete: didDelete,
                        currentDetailID: needlePendingDetail?.id
                    )

                    if selectedDetailID == nil {
                        needlePendingDetail = nil
                    }
                    if LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: didDelete) {
                        needlePendingDeletion = nil
                    }
                }
            }
        } message: { needle in
            Text("\(needle.name)을 바늘 창고에서 삭제합니다.")
        }
        .task {
            await viewModel.loadNeedles()
        }
        .refreshable {
            await viewModel.loadNeedles()
        }
        .warmScreenBackground()
    }

    private var needleList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
                    .listRowStyle()
            }

            if viewModel.hasNeedlesNeedingSync {
                syncRetryRow
                    .listRowStyle()
            }

            if viewModel.filteredNeedles.isEmpty {
                searchEmptyState
                    .listRowStyle()
            }

            ForEach(viewModel.filteredNeedles) { needle in
                Button {
                    needlePendingDetail = needle
                } label: {
                    NeedleLibraryRow(needle: needle)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppAccessibilityID.Library.needleRow(needle.id))
                .listRowStyle()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        needlePendingDeletion = needle
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
    }

    private var syncRetryRow: some View {
        SyncRetryBanner(
            message: "계정 저장 확인이 필요한 바늘이 있어요.",
            isRetrying: viewModel.isRetryingSync,
            retryAction: {
                Task {
                    await viewModel.retrySync()
                }
            }
        )
    }

    private func errorRow(message: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)

            Spacer()

            Button {
                Task {
                    await viewModel.retrySync()
                }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRetryingSync)
        }
    }

    private var searchEmptyState: some View {
        EmptyStateView(
            title: "검색 결과가 없어요.",
            description: "바늘 이름, 종류, 사이즈를 바꿔 다시 찾아보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                title: "아직 등록된 바늘이 없어요.",
                description: "바늘 종류, 사이즈, 길이를 기록해 두면 프로젝트에 맞는 도구를 빠르게 찾을 수 있어요.",
                systemImage: "ruler",
                action: {
                    isShowingAddNeedle = true
                }
            ) {
                Label("바늘 추가", systemImage: "plus")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

private struct NeedleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditForm = false
    @State private var isShowingDeleteConfirmation = false

    let needle: Needle
    let detailRows: [LibraryItemDetailRow]
    let onUpdate: (NeedleFormData) async -> Bool
    let onDelete: () async -> Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppDetailHeaderView(
                        title: needle.name,
                        subtitle: "\(needle.needleType) · \(needle.size)",
                        systemImage: "ruler",
                        tint: AppTheme.Color.sage
                    ) {
                        SyncStatusBadgeView(status: needle.syncStatus)
                    }

                    detailSection(title: "기본 정보", systemImage: "info.circle") {
                        ForEach(detailRows, id: \.title) { row in
                            NeedleDetailRowView(row: row)
                        }
                    }

                    if !trimmedNotes.isEmpty {
                        detailSection(title: "메모", systemImage: "note.text") {
                            Text(trimmedNotes)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .warmScreenBackground()
            .navigationTitle("바늘 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingEditForm = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("수정")
                    .accessibilityIdentifier(AppAccessibilityID.Library.needleEditButton)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("삭제")
                    .accessibilityIdentifier(AppAccessibilityID.Library.needleDeleteButton)
                }
            }
            .sheet(isPresented: $isShowingEditForm) {
                NeedleFormView(
                    title: "바늘 수정",
                    initialFormData: NeedleFormData(needle: needle)
                ) { formData in
                    // The form sheet dismisses itself on success; the detail screen
                    // must stay put so the user lands back on it, not the list.
                    await onUpdate(formData)
                }
            }
            .alert("바늘을 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
                Button("취소", role: .cancel) {}

                Button("삭제", role: .destructive) {
                    Task {
                        let didDelete = await onDelete()

                        if didDelete {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("\(needle.name)을 바늘 창고에서 삭제합니다.")
            }
        }
    }

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(title)

            AppSoftPanel {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
            }
        }
    }

    private var trimmedNotes: String {
        needle.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct NeedleDetailRowView: View {
    let row: LibraryItemDetailRow

    var body: some View {
        AppDetailInfoRow(
            title: row.title,
            value: row.value,
            systemImage: row.systemImage,
            tint: AppTheme.Color.sage
        )
    }
}

private struct NeedleLibraryRow: View {
    let needle: Needle

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.sageSoft)

                Image(systemName: "ruler")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.sage)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(needle.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    SyncStatusBadgeView(status: needle.syncStatus)
                }

                Text("\(needle.needleType) · \(needle.size)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let length = needle.length {
                    AppMetricChip(text: length, systemImage: "arrow.left.and.right", tint: AppTheme.Color.sage)
                }

                if !needle.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(needle.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .appCard()
    }
}

private struct NeedleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: NeedleFormData

    let title: String
    let onSave: (NeedleFormData) async -> Bool

    init(
        title: String,
        initialFormData: NeedleFormData = NeedleFormData(),
        onSave: @escaping (NeedleFormData) async -> Bool
    ) {
        self.title = title
        self.onSave = onSave
        _formData = State(initialValue: initialFormData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "기본 정보",
                        description: "프로젝트에서 바로 연결할 바늘 정보를 저장해요.",
                        systemImage: "ruler.fill",
                        tint: AppTheme.Color.sage
                    ) {
                        AppFormTextFieldRow(
                            title: "바늘 이름",
                            placeholder: "예: 치아오구 레드",
                            systemImage: "textformat",
                            text: $formData.name,
                            identifier: AppAccessibilityID.Library.needleNameField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "종류",
                            placeholder: "대바늘, 코바늘, 줄바늘",
                            systemImage: "tag",
                            text: $formData.needleType,
                            identifier: AppAccessibilityID.Library.needleTypeField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "사이즈",
                            placeholder: "예: 4.0mm",
                            systemImage: "ruler",
                            text: $formData.size,
                            identifier: AppAccessibilityID.Library.needleSizeField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "길이",
                            placeholder: "예: 80cm",
                            systemImage: "arrow.left.and.right",
                            text: $formData.length,
                            identifier: AppAccessibilityID.Library.needleLengthField
                        )
                    }

                    AppFormSection(
                        title: "메모",
                        description: "사용감, 보관 위치, 세트 정보를 남겨요.",
                        systemImage: "note.text",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextFieldRow(
                            title: "메모",
                            placeholder: "메모",
                            systemImage: "pencil.line",
                            text: $formData.notes,
                            axis: .vertical,
                            minHeight: 92,
                            identifier: AppAccessibilityID.Library.needleNotesField
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    isDisabled: !formData.canSave,
                    accessibilityIdentifier: AppAccessibilityID.Library.needleSaveButton
                ) {
                    Task {
                        let didSave = await onSave(formData)

                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
            .warmScreenBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NeedleLibraryView(libraryRepository: AppRepositoryContainer.shared.libraryRepository)
    }
}
