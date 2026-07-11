import SwiftUI

struct ProjectPatternPanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    let isCompact: Bool
    let directImportAction: () -> Void
    let scanAction: () -> Void
    let libraryAction: () -> Void
    let manualInputAction: () -> Void
    let showPDFAction: () -> Void
    let lookupAction: () -> Void
    let clearDrawingAction: () -> Void
    let unlinkAction: () -> Void

    var body: some View {
        WorkspaceSectionView(title: "도안", systemImage: "doc.text") {
            VStack(alignment: .leading, spacing: 14) {
                AppSoftPanel {
                    patternStatus
                }

                patternPreview

                AppSoftPanel {
                    modePicker
                }

                if !viewModel.relatedSkills.isEmpty {
                    AppSoftPanel {
                        detectedSkillSummary
                    }
                }

                if viewModel.interactionMode == .drawing {
                    AppSoftPanel {
                        drawingControls
                    }
                }

                patternActionButtons
            }
        }
    }

    private var patternStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.project.patternCopy?.titleSnapshot ?? "연결된 도안 없음")
                    .font(.headline)

                Spacer(minLength: 12)

                if viewModel.project.patternCopy != nil {
                    AppMetricChip(text: "연결됨", systemImage: "checkmark.circle.fill", tint: AppTheme.Color.sage)
                }
            }

            if let patternCopy = viewModel.project.patternCopy {
                if let fileName = patternCopy.fileNameSnapshot {
                    Text(fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("수동 입력 도안이라 PDF 파일은 아직 없어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("PDF 파일, 문서 스캔, 도안 창고에서 가져오기를 사용할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var patternPreview: some View {
        if let fileURL = viewModel.attachedPatternFileURL {
            ZStack(alignment: .topTrailing) {
                PDFKitView(
                    url: fileURL,
                    highlightTerms: viewModel.relatedSkills.map(\.abbreviation)
                )
                    .frame(height: isCompact ? 220 : 360)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if viewModel.interactionMode == .drawing {
                    PencilCanvasView(
                        drawingData: $viewModel.drawingData,
                        isDrawingEnabled: true,
                        onDrawingChanged: { data in
                            Task {
                                await viewModel.saveDrawingData(data)
                            }
                        }
                    )
                    .frame(height: isCompact ? 220 : 360)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        } else {
            patternPlaceholder
        }
    }

    private var patternPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.project.patternCopy == nil ? "doc.text" : "doc.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 72, height: 72)
                .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 8))

            Text(viewModel.project.patternCopy == nil ? "도안이 비어 있어요." : "PDF 파일이 없어요.")
                .font(.headline)

            Text(viewModel.project.patternCopy == nil ? "PDF를 선택하거나 iPhone 문서 스캔으로 등록하고, 필요하면 도안 창고에도 보관할 수 있어요." : "수동 도안은 이름만 저장돼요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private var modePicker: some View {
        Picker("도안 모드", selection: $viewModel.interactionMode) {
            ForEach(PatternInteractionMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .disabled(viewModel.project.patternCopy == nil)
    }

    private var detectedSkillSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("PDF에서 감지한 스킬", systemImage: "highlighter")
                .font(.subheadline.bold())

            Text("뷰어에서 해당 약어를 하이라이트하고, 행안내 스킬 태그와 사전/애니메이션으로 연결해요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            WorkspaceFlowLayout(spacing: 8) {
                ForEach(viewModel.relatedSkills.prefix(12)) { skill in
                    AppMetricChip(
                        text: skill.abbreviation,
                        systemImage: "circle.fill",
                        tint: SkillLevelFormatter.color(for: SkillLevelFormatter.normalizedLevel(skill.userLevel))
                    )
                }
            }
        }
    }

    private var drawingControls: some View {
        HStack(spacing: 10) {
            Label("도안 위에 표시할 수 있어요.", systemImage: "pencil.tip")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button(role: .destructive) {
                clearDrawingAction()
            } label: {
                Label("그리기 삭제", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.drawingData == nil || viewModel.project.patternCopy == nil)
        }
    }

    private var patternActionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    directImportAction()
                } label: {
                    Label(
                        viewModel.project.patternCopy == nil ? "PDF 직접 추가" : "PDF 교체",
                        systemImage: viewModel.project.patternCopy == nil ? "plus" : "arrow.triangle.2.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternDirectImportButton)

                Button {
                    scanAction()
                } label: {
                    Label("문서 스캔", systemImage: "doc.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternScanButton)
            }

            HStack(spacing: 10) {
                Button {
                    libraryAction()
                } label: {
                    Label("도안 창고", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternLibraryButton)

                Button {
                    manualInputAction()
                } label: {
                    Label("수동 입력", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternManualButton)

                Button {
                    showPDFAction()
                } label: {
                    Label("크게 보기", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternOpenPDFButton)
                .disabled(viewModel.attachedPatternFileURL == nil)
            }

            Button {
                lookupAction()
            } label: {
                Label("사전/스킬 찾기", systemImage: "text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternLookupButton)

            if viewModel.project.patternCopy != nil {
                Button(role: .destructive) {
                    unlinkAction()
                } label: {
                    Label("도안 연결 해제", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternUnlinkButton)
            }
        }
    }
}
