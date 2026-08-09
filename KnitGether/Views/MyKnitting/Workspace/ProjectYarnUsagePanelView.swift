import SwiftUI

struct ProjectYarnUsagePanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingLinkPicker = false
    @State private var linkPendingUnlink: ProjectYarnLink?
    let recordAction: () -> Void
    let recordForLinkAction: (ProjectYarnLink) -> Void
    let editAction: (ProjectYarnUsage) -> Void
    let deleteAction: (ProjectYarnUsage) -> Void

    var body: some View {
        WorkspaceSectionView(
            title: "실 사용량",
            systemImage: "circle.hexagongrid",
            headerAction: {
                WorkspaceHeaderActionButton(
                    systemImage: "plus",
                    label: "사용량 기록",
                    isProminent: viewModel.yarnUsages.isEmpty,
                    action: recordAction
                )
                .disabled(viewModel.project.yarnId == nil)
                .opacity(viewModel.project.yarnId == nil ? 0.35 : 1)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.yarnUsageRecordButton)
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AppSoftPanel {
                    VStack(alignment: .leading, spacing: 4) {
                        // LINK-02 v1.4: 대표 실과 추가 연결 개수를 함께 요약한다.
                        Text(yarnSummaryHeaderText)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(viewModel.yarnUsageSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                linkedYarnsBlock

                if viewModel.yarnUsages.isEmpty {
                    AppSoftPanel {
                        Text(viewModel.project.yarnId == nil ? "프로젝트 수정에서 실을 먼저 연결해 주세요." : "아직 기록된 사용량이 없어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.yarnUsages.prefix(3)) { usage in
                            yarnUsageRow(usage)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingLinkPicker) {
            YarnLinkPickerSheet(viewModel: viewModel)
        }
        .alert("실 연결을 해제할까요?", isPresented: linkUnlinkBinding, presenting: linkPendingUnlink) { link in
            Button("취소", role: .cancel) {
                linkPendingUnlink = nil
            }
            Button("연결 해제", role: .destructive) {
                Task {
                    await viewModel.unlinkYarn(link)
                    linkPendingUnlink = nil
                }
            }
        } message: { link in
            Text("\(link.nameSnapshot) 연결이 해제돼요. 창고 원본과 사용 기록은 유지돼요.")
        }
    }

    private var yarnSummaryHeaderText: String {
        let base = viewModel.project.yarnSummaryText

        if viewModel.yarnLinks.isEmpty {
            return base ?? "연결된 실 없음"
        }

        if let base {
            return "\(base) 외 \(viewModel.yarnLinks.count)개"
        }

        return "연결된 실 \(viewModel.yarnLinks.count)개"
    }

    private var linkUnlinkBinding: Binding<Bool> {
        Binding(
            get: { linkPendingUnlink != nil },
            set: { isPresented in
                if !isPresented {
                    linkPendingUnlink = nil
                }
            }
        )
    }

    @ViewBuilder
    private var linkedYarnsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("추가 연결")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    isShowingLinkPicker = true
                } label: {
                    Label("실 연결", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.Color.accent)
                .disabled(!viewModel.areMaterialLinksAvailable)
            }

            if !viewModel.areMaterialLinksAvailable {
                Text("추가 연결은 서버에 연결된 상태에서 표시돼요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if viewModel.yarnLinks.isEmpty {
                Text("대표 실 외에 함께 쓰는 실을 연결할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.yarnLinks) { link in
                        yarnLinkRow(link)
                    }
                }
            }
        }
    }

    private func yarnLinkRow(_ link: ProjectYarnLink) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.hexagongrid")
                .font(.caption)
                .foregroundStyle(AppTheme.Color.amber)

            Text(link.summaryText)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                recordForLinkAction(link)
            } label: {
                Image(systemName: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.Color.accent)
            .accessibilityLabel("\(link.nameSnapshot) 사용량 기록")

            Button(role: .destructive) {
                linkPendingUnlink = link
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(link.nameSnapshot) 연결 해제")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private func yarnUsageRow(_ usage: ProjectYarnUsage) -> some View {
        Button {
            editAction(usage)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Label("\(usage.quantityUsed)개", systemImage: "minus.circle")
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 2) {
                    if !usage.memo.isEmpty {
                        Text(usage.memo)
                            .lineLimit(1)
                    }

                    Text(formattedDate(usage.usedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(10)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .contextMenu {
            Button {
                editAction(usage)
            } label: {
                Label("수정", systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteAction(usage)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .font(.subheadline)
        .accessibilityIdentifier(AppAccessibilityID.Workspace.yarnUsageRow(usage.id))
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

private struct YarnLinkPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    private var selectableYarns: [Yarn] {
        let linkedIds = Set(viewModel.yarnLinks.compactMap(\.yarnId))
        return viewModel.availableYarns.filter { yarn in
            yarn.id != viewModel.project.yarnId && !linkedIds.contains(yarn.id)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectableYarns.isEmpty {
                    EmptyStateView(
                        title: "연결할 실이 없어요",
                        description: "창고의 모든 실이 이미 연결됐거나, 실 창고가 비어 있어요.",
                        systemImage: "circle.hexagongrid"
                    )
                    .padding()
                } else {
                    List(selectableYarns) { yarn in
                        Button {
                            Task {
                                let didLink = await viewModel.linkYarn(yarn)
                                if didLink {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(yarn.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Text(yarnDetailText(for: yarn))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
            .navigationTitle("실 추가 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func yarnDetailText(for yarn: Yarn) -> String {
        [
            yarn.brand,
            yarn.colorway,
            yarn.weight
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

struct YarnUsageRecordSheet: View {
    let title: String
    let yarnName: String
    let maxQuantity: Int?
    let cancelAction: () -> Void
    let saveAction: (Int, String) -> Void
    @Binding var quantity: Int
    @Binding var memo: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "사용한 실",
                        description: maxQuantity.map { "현재 남은 수량 \($0)개" },
                        systemImage: "circle.hexagongrid",
                        tint: AppTheme.Color.accent
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Color.accent)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("연결된 실")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(yarnName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.Color.primaryText)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 12)

                        AppFormDivider()

                        AppFormStepperRow(
                            title: "사용 수량",
                            systemImage: "minus.circle",
                            value: $quantity,
                            range: 1...max(1, maxQuantity ?? 99),
                            suffix: "개"
                        )
                        .accessibilityIdentifier(AppAccessibilityID.Workspace.yarnUsageQuantityStepper)
                    }

                    AppFormSection(
                        title: "메모",
                        description: "어느 부위에서 사용했는지 남겨두면 재고를 되돌릴 때도 편해요.",
                        systemImage: "note.text",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextFieldRow(
                            title: "메모",
                            placeholder: "예: 소매 스와치",
                            systemImage: "pencil.line",
                            text: $memo,
                            axis: .vertical,
                            minHeight: 72,
                            identifier: AppAccessibilityID.Workspace.yarnUsageMemoField
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: quantity <= 0 || maxQuantity == 0,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.yarnUsageSaveButton
                ) {
                    saveAction(quantity, memo)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        cancelAction()
                    }
                }
            }
        }
    }
}
