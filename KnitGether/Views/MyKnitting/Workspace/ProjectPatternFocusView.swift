import SwiftUI

struct ProjectPatternFocusView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @Binding var displayMode: ProjectWorkspaceDisplayMode
    let directImportAction: () -> Void
    let scanAction: () -> Void
    let libraryAction: () -> Void
    let manualInputAction: () -> Void
    let showPDFAction: () -> Void
    let lookupAction: () -> Void
    let clearDrawingAction: () -> Void
    let unlinkAction: () -> Void


    var body: some View {
        ZStack(alignment: .top) {
            patternPreview

            overlayControls
                .padding(.horizontal, 12)
                .padding(.top, 10)
        }
    }

    private var overlayControls: some View {
        HStack(spacing: 8) {
            Text(viewModel.project.patternCopy?.titleSnapshot ?? "연결된 도안 없음")
                .font(.caption.bold())
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())

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
                            viewModel.interactionMode == mode ? AnyShapeStyle(AppTheme.Color.accent) : AnyShapeStyle(.thinMaterial),
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
            Picker("보기 모드", selection: $displayMode) {
                ForEach(ProjectWorkspaceDisplayMode.selectableCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Divider()

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
                .background(.thinMaterial, in: Circle())
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(AppTheme.Color.warmBackground)
        }
    }
}
