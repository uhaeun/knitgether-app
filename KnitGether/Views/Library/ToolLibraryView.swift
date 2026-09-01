//
//  ToolLibraryView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct ToolLibraryView: View {
    @StateObject private var viewModel: ToolLibraryViewModel
    @State private var isShowingAddTool = false
    @State private var toolPendingDetail: ToolItem?
    @State private var toolPendingDeletion: ToolItem?
    @State private var isShowingDeleteConfirmation = false

    init(libraryRepository: any LibraryRepository) {
        _viewModel = StateObject(
            wrappedValue: ToolLibraryViewModel(libraryRepository: libraryRepository)
        )
    }

    var body: some View {
        Group {
            if viewModel.tools.isEmpty {
                emptyState
            } else {
                toolList
            }
        }
        .navigationTitle("도구 창고")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "도구 이름, 종류, 링크 검색"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasToolsNeedingSync {
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
                    .accessibilityLabel("도구 창고 저장 상태 다시 확인")
                }

                Button {
                    isShowingAddTool = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Library.toolAddButton)
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddTool) {
            ToolFormView(title: "도구 추가") { formData in
                await viewModel.addTool(from: formData)
            }
        }
        .sheet(item: $toolPendingDetail) { tool in
            ToolDetailView(
                viewModel: viewModel,
                tool: tool
            ) { formData in
                await viewModel.updateTool(tool, from: formData)
            } onDelete: {
                await viewModel.deleteTool(tool)
            }
        }
        .alert("도구를 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: toolPendingDeletion) { tool in
            Button("취소", role: .cancel) {
                toolPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteTool(tool)
                    let selectedDetailID = LibraryDeletionPresentation.selectedDetailID(
                        afterDeleting: tool.id,
                        didDelete: didDelete,
                        currentDetailID: toolPendingDetail?.id
                    )

                    if selectedDetailID == nil {
                        toolPendingDetail = nil
                    }
                    if LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: didDelete) {
                        toolPendingDeletion = nil
                    }
                }
            }
        } message: { tool in
            Text("\(tool.name)을 도구 창고에서 삭제합니다.")
        }
        .task {
            await viewModel.loadTools()
        }
        .refreshable {
            await viewModel.loadTools()
        }
        .warmScreenBackground()
    }

    private var toolList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
                    .listRowStyle()
            }

            if viewModel.hasToolsNeedingSync {
                syncRetryRow
                    .listRowStyle()
            }

            if viewModel.filteredTools.isEmpty {
                searchEmptyState
                    .listRowStyle()
            }

            ForEach(viewModel.filteredTools) { tool in
                Button {
                    toolPendingDetail = tool
                } label: {
                    ToolLibraryRow(tool: tool)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppAccessibilityID.Library.toolRow(tool.id))
                .listRowStyle()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        toolPendingDeletion = tool
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
            message: "계정 저장 확인이 필요한 도구가 있어요.",
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
            description: "도구 이름, 종류, 링크 키워드를 바꿔 다시 찾아보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                title: "아직 등록된 도구가 없어요.",
                description: "마커, 줄자, 코바늘, 부자재 링크를 저장해 두고 프로젝트에 연결할 수 있어요.",
                systemImage: "wrench.and.screwdriver",
                action: {
                    isShowingAddTool = true
                }
            ) {
                Label("도구 추가", systemImage: "plus")
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

private struct ToolDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditForm = false
    @State private var isShowingDeleteConfirmation = false
    @ObservedObject var viewModel: ToolLibraryViewModel

    let tool: ToolItem
    let onUpdate: (ToolFormData) async -> Bool
    let onDelete: () async -> Bool

    // 시트 아이템은 열림 시점 스냅샷이라 수정 후에도 옛 값을 그린다(결함 17 계열).
    private var currentTool: ToolItem {
        viewModel.tools.first { $0.id == tool.id } ?? tool
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppDetailHeaderView(
                        title: currentTool.name,
                        subtitle: currentTool.type,
                        systemImage: iconName,
                        tint: AppTheme.Color.amber
                    ) {
                        SyncStatusBadgeView(status: currentTool.syncStatus)
                    }

                    detailSection(title: "기본 정보", systemImage: "info.circle") {
                        ForEach(ToolLibraryViewModel.detailRows(for: currentTool), id: \.title) { row in
                            ToolDetailRowView(row: row)
                        }
                    }

                    detailSection(title: "사진", systemImage: "photo") {
                        LibraryItemPhotoContent(
                            hasPhoto: currentTool.photoByteSize != nil,
                            loadPhoto: { await viewModel.loadPhotoData(for: currentTool) },
                            uploadPhoto: { data in await viewModel.uploadPhoto(data, for: currentTool) },
                            deletePhoto: { await viewModel.deletePhoto(for: currentTool) }
                        )
                    }

                    if let url = linkURL {
                        detailSection(title: "링크", systemImage: "link") {
                        Link(destination: url) {
                            Label(currentTool.link ?? url.absoluteString, systemImage: "link")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Color.accent)
                                .lineLimit(2)
                        }
                        }
                    }

                    if !trimmedMemo.isEmpty {
                        detailSection(title: "메모", systemImage: "note.text") {
                            Text(trimmedMemo)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .warmScreenBackground()
            .navigationTitle("도구 상세")
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
                    .accessibilityIdentifier(AppAccessibilityID.Library.toolEditButton)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("삭제")
                    .accessibilityIdentifier(AppAccessibilityID.Library.toolDeleteButton)
                }
            }
            .sheet(isPresented: $isShowingEditForm) {
                ToolFormView(
                    title: "도구 수정",
                    initialFormData: ToolFormData(tool: currentTool)
                ) { formData in
                    // The form sheet dismisses itself on success; the detail screen
                    // must stay put so the user lands back on it, not the list.
                    await onUpdate(formData)
                }
            }
            .alert("도구를 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
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
                Text("\(currentTool.name)을 도구 창고에서 삭제합니다.")
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

    private var trimmedMemo: String {
        currentTool.memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var linkURL: URL? {
        guard let link = currentTool.link?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty else {
            return nil
        }

        if let url = URL(string: link), url.scheme != nil {
            return url
        }

        return URL(string: "https://\(link)")
    }

    private var iconName: String {
        ToolLibraryRow.iconName(for: currentTool.type)
    }
}

private struct ToolDetailRowView: View {
    let row: LibraryItemDetailRow

    var body: some View {
        AppDetailInfoRow(
            title: row.title,
            value: row.value,
            systemImage: row.systemImage,
            tint: AppTheme.Color.amber
        )
    }
}

private struct ToolLibraryRow: View {
    let tool: ToolItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.amberSoft)

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.amber)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(tool.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    SyncStatusBadgeView(status: tool.syncStatus)
                }

                Text(tool.type)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let link = tool.link, !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    AppMetricChip(text: link, systemImage: "link", tint: AppTheme.Color.accent)
                        .lineLimit(1)
                }

                if !tool.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(tool.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .appCard()
    }

    private var iconName: String {
        Self.iconName(for: tool.type)
    }

    static func iconName(for typeValue: String) -> String {
        let type = typeValue.lowercased()
        if type.contains("마커") || type.contains("marker") {
            return "tag"
        }
        if type.contains("줄자") || type.contains("measure") {
            return "ruler"
        }
        if type.contains("코바늘") || type.contains("hook") {
            return "hook"
        }
        return "wrench.and.screwdriver"
    }
}

struct ToolFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: ToolFormData

    let title: String
    let onSave: (ToolFormData) async -> Bool

    init(
        title: String,
        initialFormData: ToolFormData = ToolFormData(),
        onSave: @escaping (ToolFormData) async -> Bool
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
                        description: "프로젝트 작업공간에서 연결할 도구를 저장해요.",
                        systemImage: "wrench.and.screwdriver.fill",
                        tint: AppTheme.Color.amber
                    ) {
                        AppFormTextFieldRow(
                            title: "도구 이름",
                            placeholder: "예: 코마커 세트",
                            systemImage: "textformat",
                            text: $formData.name,
                            identifier: AppAccessibilityID.Library.toolNameField,
                            isRequired: true,
                            characterLimit: AppInputLimit.name
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "종류",
                            placeholder: "마커, 줄자, 돗바늘 등",
                            systemImage: "tag",
                            text: $formData.type,
                            identifier: AppAccessibilityID.Library.toolTypeField,
                            isRequired: true
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "링크",
                            placeholder: "구매 링크 또는 참고 링크",
                            systemImage: "link",
                            text: $formData.link,
                            identifier: AppAccessibilityID.Library.toolLinkField
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    }

                    AppFormSection(
                        title: "메모",
                        description: "보관 위치나 같이 쓰는 프로젝트를 남겨요.",
                        systemImage: "note.text",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextFieldRow(
                            title: "메모",
                            placeholder: "메모",
                            systemImage: "pencil.line",
                            text: $formData.memo,
                            axis: .vertical,
                            minHeight: 92,
                            identifier: AppAccessibilityID.Library.toolMemoField,
                            characterLimit: AppInputLimit.memo
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
                    accessibilityIdentifier: AppAccessibilityID.Library.toolSaveButton
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
        ToolLibraryView(libraryRepository: AppRepositoryContainer.shared.libraryRepository)
    }
}
