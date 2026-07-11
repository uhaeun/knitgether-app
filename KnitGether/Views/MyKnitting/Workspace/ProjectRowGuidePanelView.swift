import SwiftUI

struct ProjectRowGuidePanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    let addAction: () -> Void
    let bulkAddAction: () -> Void
    let renumberAction: () -> Void
    let addSuggestedAction: (PatternRowInstructionSuggestion) -> Void
    let editAction: (RowInstruction) -> Void
    let deleteAction: (RowInstruction) -> Void
    let skillTapAction: (ResolvedSkillTag) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("각 단에 해야 할 작업을 적어두고 한 단씩 따라갈 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            AppSoftPanel {
                currentRowSkillSummary
            }

            if !viewModel.currentLearningSkillTags.isEmpty {
                AppSoftPanel {
                    learningRecommendations
                }
            }

            if !viewModel.patternRowInstructionSuggestions.isEmpty {
                AppSoftPanel {
                    patternSuggestionSection
                }
            }

            AppSoftPanel {
                currentRowInstruction
            }

            actionButtons
            instructionList
        }
    }

    private var currentRowSkillSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이번 단 스킬")
                .font(.subheadline.bold())

            if viewModel.currentResolvedSkillTags.isEmpty {
                Text("현재 단에 등록된 스킬 태그가 없어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                WorkspaceFlowLayout(spacing: 8) {
                    ForEach(viewModel.currentResolvedSkillTags) { tag in
                        SkillTagChipView(tag: tag, tapAction: skillTapAction)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var learningRecommendations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("이번 단에서 먼저 확인할 스킬", systemImage: "lightbulb")
                .font(.subheadline.bold())

            Text("스킬 테스트에서 몰라요/헷갈려요로 표시한 스킬이에요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(viewModel.currentLearningSkillTags) { tag in
                    Button {
                        skillTapAction(tag)
                    } label: {
                        HStack(spacing: 10) {
                            SkillTagChipView(tag: tag)

                            Text(tag.detailText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "play.circle")
                                .foregroundStyle(AppTheme.Color.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var patternSuggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("도안에서 찾은 행안내 후보", systemImage: "text.badge.plus")
                .font(.subheadline.bold())

            Text("PDF/OCR에서 감지한 뜨개 약어가 포함된 줄이에요. 필요한 줄만 골라 행안내에 추가하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(viewModel.patternRowInstructionSuggestions.prefix(5)) { suggestion in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(suggestion.rowNumber)단")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(AppTheme.Color.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.Color.accentSoft, in: Capsule())

                            Text(suggestion.instructionText)
                                .font(.subheadline)
                                .lineLimit(2)

                            Spacer(minLength: 8)

                            Button {
                                addSuggestedAction(suggestion)
                            } label: {
                                Label("추가", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityIdentifier(AppAccessibilityID.Workspace.rowInstructionSuggestionAddButton(suggestion.rowNumber))
                        }

                        WorkspaceFlowLayout(spacing: 6) {
                            ForEach(suggestion.skillTags, id: \.self) { skillTag in
                                AppMetricChip(text: skillTag, systemImage: "tag", tint: AppTheme.Color.sage)
                            }
                        }
                    }
                    .padding(10)
                    .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentRowInstruction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("현재 행안내", systemImage: "list.number")
                .font(.subheadline.bold())

            if let instruction = viewModel.currentInstruction {
                Text(instruction.instructionText)
                    .font(.body)
            } else {
                Text(viewModel.currentRow == 0 ? "다음 단을 누르면 행안내를 따라갈 수 있어요." : "현재 단에 등록된 행안내가 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    addAction()
                } label: {
                    Label("행안내 추가", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.rowInstructionAddButton)

                Button {
                    bulkAddAction()
                } label: {
                    Label("여러 줄 붙여넣기", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.rowInstructionBulkButton)
            }

            Button {
                renumberAction()
            } label: {
                Label("행 번호 정리", systemImage: "arrow.up.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.rowCounter.rowInstructions.isEmpty)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.rowInstructionRenumberButton)
        }
    }

    private var instructionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("등록된 행안내")
                .font(.subheadline.bold())

            if viewModel.rowCounter.rowInstructions.isEmpty {
                EmptyStateView(
                    title: "아직 등록된 행안내가 없어요.",
                    description: "행안내를 추가하거나 여러 줄 붙여넣기로 도안의 지시문을 옮겨오세요.",
                    systemImage: "list.number"
                )
            } else {
                ForEach(viewModel.rowCounter.rowInstructions) { instruction in
                    ProjectRowInstructionRowView(
                        instruction: instruction,
                        resolvedTags: viewModel.resolvedSkillTags(for: instruction),
                        skillTapAction: skillTapAction,
                        editAction: {
                            editAction(instruction)
                        },
                        deleteAction: {
                            deleteAction(instruction)
                        }
                    )
                }
            }
        }
    }
}

struct ProjectRowInstructionRowView: View {
    let instruction: RowInstruction
    let resolvedTags: [ResolvedSkillTag]
    let skillTapAction: (ResolvedSkillTag) -> Void
    let editAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(instruction.rowNumber)단")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(AppTheme.Color.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppTheme.Color.accentSoft, in: Capsule())
                    .monospacedDigit()

                Spacer()

                Button(action: editAction) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("행안내 수정")

                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("행안내 삭제")
            }

            Text(instruction.instructionText)

            if !resolvedTags.isEmpty {
                WorkspaceFlowLayout(spacing: 8) {
                    ForEach(resolvedTags) { tag in
                        SkillTagChipView(tag: tag, tapAction: skillTapAction)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .accessibilityIdentifier(AppAccessibilityID.Workspace.rowInstruction(instruction.id))
    }
}
