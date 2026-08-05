import SwiftUI

struct ProjectPatternFocusView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    let directImportAction: () -> Void
    let scanAction: () -> Void
    let libraryAction: () -> Void
    let manualInputAction: () -> Void
    let showPDFAction: () -> Void
    let lookupAction: () -> Void
    let clearDrawingAction: () -> Void
    let unlinkAction: () -> Void

    private var previewHeight: CGFloat {
        UIScreen.main.bounds.height * 0.55
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            patternPreview
        }
        .padding(12)
        .appCard(cornerRadius: 20)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(viewModel.project.patternCopy?.titleSnapshot ?? "연결된 도안 없음")
                .font(.subheadline.bold())
                .lineLimit(1)

            Spacer(minLength: 8)

            modeToggle
            actionMenu
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(PatternInteractionMode.allCases) { mode in
                Button {
                    viewModel.interactionMode = mode
                } label: {
                    Image(systemName: mode == .viewer ? "eye" : "pencil.tip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.interactionMode == mode ? .white : AppTheme.Color.accent)
                        .frame(width: 34, height: 34)
                        .background(
                            viewModel.interactionMode == mode ? AppTheme.Color.accent : AppTheme.Color.accentSoft,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.rawValue)
            }
        }
        .disabled(viewModel.project.patternCopy == nil)
        .accessibilityIdentifier(AppAccessibilityID.Workspace.patternFocusModeToggle)
    }

    private var actionMenu: some View {
        Menu {
            Button {
                directImportAction()
            } label: {
                Label(
                    viewModel.project.patternCopy == nil ? "PDF 직접 추가" : "PDF 교체",
                    systemImage: viewModel.project.patternCopy == nil ? "plus" : "arrow.triangle.2.circlepath"
                )
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternDirectImportButton)

            Button {
                scanAction()
            } label: {
                Label("문서 스캔", systemImage: "doc.viewfinder")
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternScanButton)

            Button {
                libraryAction()
            } label: {
                Label("도안 창고", systemImage: "books.vertical")
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternLibraryButton)

            Button {
                manualInputAction()
            } label: {
                Label("수동 입력", systemImage: "keyboard")
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternManualButton)

            Button {
                showPDFAction()
            } label: {
                Label("크게 보기", systemImage: "doc.text.magnifyingglass")
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternOpenPDFButton)
            .disabled(viewModel.attachedPatternFileURL == nil)

            Button {
                lookupAction()
            } label: {
                Label("사전/스킬 찾기", systemImage: "text.magnifyingglass")
            }
            .accessibilityIdentifier(AppAccessibilityID.Workspace.patternLookupButton)

            if viewModel.drawingData != nil && viewModel.project.patternCopy != nil {
                Button(role: .destructive) {
                    clearDrawingAction()
                } label: {
                    Label("그리기 삭제", systemImage: "trash")
                }
            }

            if viewModel.project.patternCopy != nil {
                Button(role: .destructive) {
                    unlinkAction()
                } label: {
                    Label("도안 연결 해제", systemImage: "xmark.circle")
                }
                .accessibilityIdentifier(AppAccessibilityID.Workspace.patternUnlinkButton)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.Color.accentSoft, in: Circle())
        }
        .accessibilityIdentifier(AppAccessibilityID.Workspace.patternFocusMenuButton)
    }

    @ViewBuilder
    private var patternPreview: some View {
        if let fileURL = viewModel.attachedPatternFileURL {
            ZStack {
                PDFKitView(
                    url: fileURL,
                    highlightTerms: viewModel.relatedSkills.map(\.abbreviation)
                )
                .frame(height: previewHeight)
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
                    .frame(height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: viewModel.project.patternCopy == nil ? "doc.text" : "doc.questionmark")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 72, height: 72)
                    .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 8))

                Text(viewModel.project.patternCopy == nil ? "도안이 비어 있어요." : "PDF 파일이 없어요.")
                    .font(.headline)

                Text(viewModel.project.patternCopy == nil ? "오른쪽 위 메뉴에서 PDF 추가, 문서 스캔, 도안 창고 가져오기를 쓸 수 있어요." : "수동 도안은 이름만 저장돼요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: previewHeight)
            .padding()
            .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
            }
        }
    }
}
