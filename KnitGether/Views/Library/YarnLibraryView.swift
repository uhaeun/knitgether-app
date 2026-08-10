//
//  YarnLibraryView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct YarnLibraryView: View {
    @StateObject private var viewModel: YarnLibraryViewModel
    @State private var isShowingAddYarn = false
    @State private var yarnPendingDetail: Yarn?
    @State private var yarnPendingDeletion: Yarn?
    @State private var isShowingDeleteConfirmation = false

    init(libraryRepository: any LibraryRepository) {
        _viewModel = StateObject(
            wrappedValue: YarnLibraryViewModel(libraryRepository: libraryRepository)
        )
    }

    var body: some View {
        Group {
            if viewModel.yarns.isEmpty {
                emptyState
            } else {
                yarnList
            }
        }
        .navigationTitle("실 창고")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "실 이름, 브랜드, 색상 검색"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.hasYarnsNeedingSync {
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
                    .accessibilityLabel("실 창고 저장 상태 다시 확인")
                }

                Button {
                    isShowingAddYarn = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AppAccessibilityID.Library.yarnAddButton)
                .accessibilityLabel("추가")
            }
        }
        .sheet(isPresented: $isShowingAddYarn) {
            YarnFormView(title: "실 추가") { formData in
                await viewModel.addYarn(from: formData)
            }
        }
        .sheet(item: $yarnPendingDetail) { yarn in
            YarnDetailView(
                viewModel: viewModel,
                yarn: yarn
            ) { formData in
                await viewModel.updateYarn(yarn, from: formData)
            } onDelete: {
                await viewModel.deleteYarn(yarn)
            }
        }
        .alert("실을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: yarnPendingDeletion) { yarn in
            Button("취소", role: .cancel) {
                yarnPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteYarn(yarn)
                    let selectedDetailID = LibraryDeletionPresentation.selectedDetailID(
                        afterDeleting: yarn.id,
                        didDelete: didDelete,
                        currentDetailID: yarnPendingDetail?.id
                    )

                    if selectedDetailID == nil {
                        yarnPendingDetail = nil
                    }
                    if LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: didDelete) {
                        yarnPendingDeletion = nil
                    }
                }
            }
        } message: { yarn in
            Text("\(yarn.name)을 실 창고에서 삭제합니다.")
        }
        .task {
            await viewModel.loadYarns()
        }
        .refreshable {
            await viewModel.loadYarns()
        }
        .warmScreenBackground()
    }

    private var yarnList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                errorRow(message: errorMessage)
                    .listRowStyle()
            }

            if viewModel.hasYarnsNeedingSync {
                syncRetryRow
                    .listRowStyle()
            }

            if viewModel.filteredYarns.isEmpty {
                searchEmptyState
                    .listRowStyle()
            }

            ForEach(viewModel.filteredYarns) { yarn in
                Button {
                    yarnPendingDetail = yarn
                } label: {
                    YarnLibraryRow(yarn: yarn)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppAccessibilityID.Library.yarnRow(yarn.id))
                .listRowStyle()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        yarnPendingDeletion = yarn
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
            message: "계정 저장 확인이 필요한 실이 있어요.",
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
            description: "다른 이름, 브랜드, 색상으로 다시 찾아보세요.",
            systemImage: "magnifyingglass"
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                title: "아직 등록된 실이 없어요.",
                description: "실 이름, 굵기, 색상, 보유 수량을 기록해 두면 프로젝트 준비가 쉬워져요.",
                systemImage: "circle.hexagongrid",
                action: {
                    isShowingAddYarn = true
                }
            ) {
                Label("실 추가", systemImage: "plus")
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

private struct YarnDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditForm = false
    @State private var isShowingDeleteConfirmation = false
    @ObservedObject var viewModel: YarnLibraryViewModel

    let yarn: Yarn
    let onUpdate: (YarnFormData) async -> Bool
    let onDelete: () async -> Bool

    // 시트 아이템은 열림 시점 스냅샷이라 수정이나 새로고침 후에도 옛 값을 그린다(결함 17).
    // 표시는 항상 뷰모델의 최신 값을 쓴다.
    private var currentYarn: Yarn {
        viewModel.yarns.first { $0.id == yarn.id } ?? yarn
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppDetailHeaderView(
                        title: currentYarn.name,
                        subtitle: subtitle,
                        systemImage: "circle.hexagongrid",
                        tint: AppTheme.Color.amber
                    ) {
                        SyncStatusBadgeView(status: currentYarn.syncStatus)
                    }

                    detailSection(title: "기본 정보", systemImage: "info.circle") {
                        ForEach(YarnLibraryViewModel.detailRows(for: currentYarn), id: \.title) { row in
                            YarnDetailRowView(row: row)
                        }
                    }

                    detailSection(title: "사진", systemImage: "photo") {
                        LibraryItemPhotoContent(
                            hasPhoto: currentYarn.photoByteSize != nil,
                            loadPhoto: { await viewModel.loadPhotoData(for: currentYarn) },
                            uploadPhoto: { data in await viewModel.uploadPhoto(data, for: currentYarn) },
                            deletePhoto: { await viewModel.deletePhoto(for: currentYarn) }
                        )
                    }

                    if !trimmedNotes.isEmpty {
                        detailSection(title: "메모", systemImage: "note.text") {
                            Text(trimmedNotes)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    detailSection(title: "프로젝트 사용처", systemImage: "shippingbox") {
                        if usageRecords.isEmpty {
                            Text("아직 이 실을 사용한 프로젝트 기록이 없어요.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            AppMetricChip(
                                text: "누적 사용 \(viewModel.totalUsedQuantity(for: currentYarn))개",
                                systemImage: "number",
                                tint: AppTheme.Color.amber
                            )

                            ForEach(Array(usageRecords.enumerated()), id: \.element.id) { index, usage in
                                if index > 0 {
                                    Divider()
                                }

                                YarnUsageDestinationRow(usage: usage)
                            }
                        }
                    }
                }
                .padding()
            }
            .warmScreenBackground()
            .refreshable {
                // 새로고침은 사용 기록만이 아니라 실 목록도 서버에서 다시 가져온다(결함 17).
                await viewModel.loadYarns()
                await viewModel.loadYarnUsages(for: currentYarn)
            }
            .navigationTitle("실 상세")
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
                    .accessibilityIdentifier(AppAccessibilityID.Library.yarnEditButton)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("삭제")
                    .accessibilityIdentifier(AppAccessibilityID.Library.yarnDeleteButton)
                }
            }
            .sheet(isPresented: $isShowingEditForm) {
                YarnFormView(
                    title: "실 수정",
                    initialFormData: YarnFormData(yarn: currentYarn)
                ) { formData in
                    // The form sheet dismisses itself on success; the detail screen
                    // must stay put so the user lands back on it, not the list.
                    await onUpdate(formData)
                }
            }
            .alert("실을 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
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
                Text("\(currentYarn.name)을 실 창고에서 삭제합니다.")
            }
            .task(id: yarn.id) {
                await viewModel.loadYarnUsages(for: yarn)
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

    private var subtitle: String? {
        [currentYarn.brand, currentYarn.colorway]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
            .nilIfEmpty
    }

    private var trimmedNotes: String {
        currentYarn.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var usageRecords: [ProjectYarnUsage] {
        viewModel.yarnUsageRecords(for: currentYarn)
    }
}

private struct YarnUsageDestinationRow: View {
    let usage: ProjectYarnUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(projectName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer(minLength: 12)

                Text("\(usage.quantityUsed)개")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 8) {
                Text(formattedDate(usage.usedAt))

                if !trimmedMemo.isEmpty {
                    Text(trimmedMemo)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var projectName: String {
        usage.projectNameSnapshot?.nilIfEmpty ?? "프로젝트"
    }

    private var trimmedMemo: String {
        usage.memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

private struct YarnDetailRowView: View {
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

private struct YarnLibraryRow: View {
    let yarn: Yarn

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.amberSoft)

                Image(systemName: "circle.hexagongrid")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.amber)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(yarn.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    SyncStatusBadgeView(status: yarn.syncStatus)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let weight = yarn.weight {
                        AppMetricChip(text: weight, systemImage: "scalemass", tint: AppTheme.Color.amber)
                    }

                    AppMetricChip(text: "\(yarn.quantity)개", systemImage: "number", tint: AppTheme.Color.accent)
                }

                if !yarn.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(yarn.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .appCard()
    }

    private var subtitle: String? {
        [yarn.brand, yarn.colorway]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
            .nilIfEmpty
    }
}

struct YarnFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: YarnFormData

    let title: String
    let onSave: (YarnFormData) async -> Bool

    init(
        title: String,
        initialFormData: YarnFormData = YarnFormData(),
        onSave: @escaping (YarnFormData) async -> Bool
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
                        description: "프로젝트에 연결할 실 정보를 저장해요.",
                        systemImage: "circle.hexagongrid.fill",
                        tint: AppTheme.Color.rose
                    ) {
                        AppFormTextFieldRow(
                            title: "실 이름",
                            placeholder: "예: Cotton DK",
                            systemImage: "textformat",
                            text: $formData.name,
                            identifier: AppAccessibilityID.Library.yarnNameField,
                            isRequired: true
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "브랜드",
                            placeholder: "브랜드",
                            systemImage: "tag",
                            text: $formData.brand,
                            identifier: AppAccessibilityID.Library.yarnBrandField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "색상",
                            placeholder: "색상 이름 또는 번호",
                            systemImage: "paintpalette",
                            text: $formData.colorway,
                            identifier: AppAccessibilityID.Library.yarnColorwayField
                        )

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "굵기",
                            placeholder: "DK, Worsted 등",
                            systemImage: "scalemass",
                            text: $formData.weight,
                            identifier: AppAccessibilityID.Library.yarnWeightField
                        )

                        AppFormDivider()

                        AppFormStepperRow(
                            title: "수량",
                            systemImage: "number",
                            value: $formData.quantity,
                            range: 0...999,
                            suffix: "개"
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Library.yarnQuantityStepper)
                    }

                    AppFormSection(
                        title: "메모",
                        description: "구매처, 로트 번호, 사용 예정 프로젝트를 남겨요.",
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
                            identifier: AppAccessibilityID.Library.yarnNotesField
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
                    accessibilityIdentifier: AppAccessibilityID.Library.yarnSaveButton
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    NavigationStack {
        YarnLibraryView(libraryRepository: AppRepositoryContainer.shared.libraryRepository)
    }
}
