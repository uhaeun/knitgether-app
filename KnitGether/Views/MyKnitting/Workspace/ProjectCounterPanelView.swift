import SwiftUI

struct ProjectCounterPanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @Binding var sectionNameText: String
    @Binding var counterMemoText: String
    let counterMode: Binding<RowCounterMode>
    let decrementAction: () -> Void
    let incrementAction: () -> Void
    let editCurrentRowAction: () -> Void
    let editTargetRowAction: () -> Void
    let saveSectionNameAction: () -> Void
    let editMemoAction: () -> Void
    let resetAction: () -> Void
    let addRowInstructionAction: () -> Void
    let bulkAddRowInstructionsAction: () -> Void
    let renumberRowInstructionsAction: () -> Void
    let addSuggestedRowInstructionAction: (PatternRowInstructionSuggestion) -> Void
    let editRowInstructionAction: (RowInstruction) -> Void
    let deleteRowInstructionAction: (RowInstruction) -> Void
    let skillTapAction: (ResolvedSkillTag) -> Void

    var body: some View {
        WorkspaceSectionView(title: "단수 카운터", systemImage: "number.circle") {
            VStack(alignment: .leading, spacing: 16) {
                AppSoftPanel {
                    Picker("카운터 모드", selection: counterMode) {
                        ForEach(RowCounterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.counterModePicker)
                }

                AppSoftPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        currentRowSummary
                        Divider()
                        counterProgress
                    }
                }

                rowControlButtons

                AppSoftPanel {
                    editButtons
                }

                AppSoftPanel {
                    sectionEditor
                }

                AppSoftPanel {
                    memoPreview
                }

                if viewModel.rowCounter.mode == .rowGuide {
                    ProjectRowGuidePanelView(
                        viewModel: viewModel,
                        addAction: addRowInstructionAction,
                        bulkAddAction: bulkAddRowInstructionsAction,
                        renumberAction: renumberRowInstructionsAction,
                        addSuggestedAction: addSuggestedRowInstructionAction,
                        editAction: editRowInstructionAction,
                        deleteAction: deleteRowInstructionAction,
                        skillTapAction: skillTapAction
                    )
                }
            }
        }
    }

    private var currentRowSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: viewModel.currentRow == 0 ? "시작 전" : "현재 \(viewModel.currentRow)단")
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.counterCurrent)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                if let targetRow = viewModel.rowCounter.targetRow {
                    Text(verbatim: "\(viewModel.currentRow) / \(targetRow)단")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Text("총 단수 미설정")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Text("섹션: \(sectionDisplayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var counterProgress: some View {
        if let progress = viewModel.rowGuideProgress {
            ProgressView(value: progress)
            Text("진행률 \(Int((progress * 100).rounded()))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("총 단수를 설정하면 진행률이 표시돼요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var rowControlButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                decrementAction()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Color.accent)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.Color.accentSoft, in: Circle())

                    Text(viewModel.rowCounter.mode == .rowGuide ? "이전 행" : "이전 단")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterPreviousButton)
            .disabled(viewModel.currentRow == 0)
            .opacity(viewModel.currentRow == 0 ? 0.4 : 1)

            Button {
                incrementAction()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.Color.accent, in: Circle())

                    Text(viewModel.rowCounter.mode == .rowGuide ? "다음 행" : "다음 단")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterNextButton)
        }
    }

    private var editButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    editCurrentRowAction()
                } label: {
                    Label("현재 단수", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.counterEditCurrentButton)

                Button {
                    editTargetRowAction()
                } label: {
                    Label("총 단수", systemImage: "target")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.counterEditTargetButton)
            }

            Button(role: .destructive) {
                resetAction()
            } label: {
                Label("단수 리셋", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.currentRow == 0)
        }
    }

    private var sectionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("섹션")
                .font(.subheadline.bold())

            HStack {
                TextField("섹션 없음", text: $sectionNameText)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.counterSectionField)

                Button("저장") {
                    saveSectionNameAction()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.counterSectionSaveButton)
            }
        }
    }

    private var memoPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let memo = viewModel.rowCounter.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("카운터 메모가 비어 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                editMemoAction()
            } label: {
                Label("카운터 메모", systemImage: "note.text")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterMemoButton)
        }
    }

    private var sectionDisplayName: String {
        let sectionName = viewModel.rowCounter.sectionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return sectionName.isEmpty ? "섹션 없음" : sectionName
    }
}
