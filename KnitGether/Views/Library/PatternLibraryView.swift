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
    @State private var isShowingDocumentScanner = false
    @State private var patternPendingDetail: PatternDocument?
    @State private var patternPendingEdit: PatternDocument?
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
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "도안 제목, 디자이너, 파일명 검색"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasPatternsNeedingSync {
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
                    .accessibilityLabel("도안 창고 저장 상태 다시 확인")
                }

                Menu {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("PDF 파일 선택", systemImage: "doc.badge.plus")
                    }

                    Button {
                        isShowingDocumentScanner = true
                    } label: {
                        Label("문서 스캔", systemImage: "doc.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Library.patternAddButton)
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
        .sheet(isPresented: $isShowingDocumentScanner) {
            DocumentScannerView { result in
                isShowingDocumentScanner = false
                handleScannedPatternResult(result)
            }
        }
        .sheet(item: $patternPendingDetail) { pattern in
            PatternDetailView(
                pattern: pattern,
                fileURL: viewModel.fileURL(for: pattern)
            ) {
                patternPendingDetail = nil
                patternPendingEdit = pattern
            }
        }
        .sheet(item: $patternPendingEdit) { pattern in
            PatternFormView(
                title: "도안 수정",
                initialFormData: PatternFormData(pattern: pattern)
            ) { formData in
                await viewModel.updatePattern(pattern, from: formData)
            }
        }
        .alert("도안을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: patternPendingDeletion) { pattern in
            Button("취소", role: .cancel) {
                patternPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deletePattern(pattern)

                    if didDelete {
                        patternPendingDeletion = nil
                    }
                }
            }
        } message: { _ in
            Text("Library 원본만 삭제돼요. 프로젝트에 가져온 도안 사본은 유지돼요.")
        }
        .task {
            await viewModel.loadPatterns()
        }
        .refreshable {
            await viewModel.loadPatterns()
        }
        .warmScreenBackground()
    }

    private var patternList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
                    .listRowStyle()
            }

            if viewModel.hasPatternsNeedingSync {
                syncRetryRow
                    .listRowStyle()
            }

            if viewModel.filteredPatterns.isEmpty {
                searchEmptyState
                    .listRowStyle()
            }

            ForEach(viewModel.filteredPatterns) { pattern in
                Button {
                    Task {
                        patternPendingDetail = await viewModel.preparePatternForViewing(pattern)
                    }
                } label: {
                    PatternLibraryRow(pattern: pattern)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppAccessibilityID.Library.patternRow(pattern.id))
                .listRowStyle()
                .swipeActions(edge: .trailing) {
                    Button {
                        patternPendingEdit = pattern
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        patternPendingDeletion = pattern
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
            message: "계정 저장 확인이 필요한 도안이 있어요.",
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
            description: "도안 제목, 디자이너, 파일명으로 다시 찾아보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                title: "아직 등록된 도안이 없어요.",
                description: "PDF 파일을 추가하거나 iPhone 문서 스캔으로 Library에 보관하고 프로젝트 작업공간으로 가져올 수 있어요.",
                systemImage: "doc.text",
                action: {
                    isShowingFileImporter = true
                }
            ) {
                Label("도안 추가", systemImage: "plus")
            }

            Button {
                isShowingDocumentScanner = true
            } label: {
                Label("문서 스캔", systemImage: "doc.viewfinder")
            }
            .buttonStyle(.bordered)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
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

    private func handleScannedPatternResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let fileURL):
            Task {
                await viewModel.addPattern(fromFileAt: fileURL)
            }
        case .failure:
            break
        }
    }
}

private struct PatternDetailView: View {
    let pattern: PatternDocument
    let fileURL: URL?
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppDetailHeaderView(
                        title: pattern.title,
                        subtitle: pattern.designer,
                        systemImage: "doc.richtext",
                        tint: AppTheme.Color.accent
                    ) {
                        SyncStatusBadgeView(status: pattern.syncStatus)
                    }

                    AppSoftPanel {
                        if let fileURL {
                            NavigationLink {
                                PDFKitView(url: fileURL)
                                    .navigationTitle(pattern.title)
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.richtext")
                                        .foregroundStyle(AppTheme.Color.accent)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("PDF 열기")
                                            .font(.headline)

                                        Text(pattern.fileName ?? "등록된 PDF")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.Color.accent.opacity(0.55))
                                }
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Label("PDF 파일 없음", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                        }
                    }

                    detailSection(title: "기본 정보", systemImage: "info.circle") {
                        metadataRow(title: "제목", value: pattern.title, systemImage: "textformat")

                        if let designer = pattern.designer, !designer.isEmpty {
                            metadataRow(title: "디자이너", value: designer, systemImage: "person")
                        }

                        if let pageCount = pattern.pageCount {
                            metadataRow(title: "페이지", value: "\(pageCount)", systemImage: "doc.on.doc")
                        }

                        if let fileName = pattern.fileName {
                            metadataRow(title: "파일", value: fileName, systemImage: "paperclip")
                        }
                    }

                    if !pattern.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        detailSection(title: "메모", systemImage: "note.text") {
                            Text(pattern.notes)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .warmScreenBackground()
            .navigationTitle(pattern.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("수정", action: onEdit)
                        .accessibilityIdentifier(AppAccessibilityID.Library.patternEditButton)
                }
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

    private func metadataRow(title: String, value: String, systemImage: String) -> some View {
        AppDetailInfoRow(
            title: title,
            value: value,
            systemImage: systemImage,
            tint: AppTheme.Color.accent
        )
    }
}

private struct PatternFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: PatternFormData

    let title: String
    let onSave: (PatternFormData) async -> Bool

    init(
        title: String,
        initialFormData: PatternFormData = PatternFormData(),
        onSave: @escaping (PatternFormData) async -> Bool
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
                        description: "프로젝트에 연결할 때 보일 도안 정보를 정리해요.",
                        systemImage: "doc.text.fill",
                        tint: AppTheme.Color.accent
                    ) {
                        AppFormTextFieldRow(
                            title: "도안 제목",
                            placeholder: "예: 여름 가디건",
                            systemImage: "textformat",
                            text: $formData.title,
                            identifier: AppAccessibilityID.Library.patternTitleField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "디자이너",
                            placeholder: "디자이너 또는 브랜드",
                            systemImage: "person",
                            text: $formData.designer,
                            identifier: AppAccessibilityID.Library.patternDesignerField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "페이지 수",
                            placeholder: "0",
                            systemImage: "number",
                            text: $formData.pageCountText,
                            identifier: AppAccessibilityID.Library.patternPageCountField
                        )
                        .keyboardType(.numberPad)
                    }

                    AppFormSection(
                        title: "메모",
                        description: "실수하기 쉬운 부분이나 구매처를 적어둘 수 있어요.",
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
                            identifier: AppAccessibilityID.Library.patternNotesField
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
                    accessibilityIdentifier: AppAccessibilityID.Library.patternSaveButton
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

private struct PatternLibraryRow: View {
    let pattern: PatternDocument

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.accentSoft)

                Image(systemName: "doc.richtext")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.accent)
            }
            .frame(width: 56, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    SyncStatusBadgeView(status: pattern.syncStatus)
                }

                Text(pattern.fileName ?? "파일 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("등록일 \(formattedDate(pattern.createdAt))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Color.accentSoft, in: Capsule())

                if !pattern.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(pattern.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .appCard()
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
