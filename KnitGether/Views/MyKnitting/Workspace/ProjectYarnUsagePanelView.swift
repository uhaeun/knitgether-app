import SwiftUI

struct ProjectYarnUsagePanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    let recordAction: () -> Void
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
                        Text(viewModel.project.yarnSummaryText ?? "연결된 실 없음")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(viewModel.yarnUsageSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

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
