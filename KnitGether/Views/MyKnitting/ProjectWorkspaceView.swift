//
//  ProjectWorkspaceView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectWorkspaceView: View {
    enum WorkspaceTab: Hashable {
        case working
        case info
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProjectWorkspaceViewModel
    @State private var selectedTab: WorkspaceTab
    @State private var isShowingEditProject = false
    @State private var isShowingDirectPatternImporter = false
    @State private var isShowingPatternDocumentScanner = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingPDFViewer = false
    @State private var isShowingManualPatternSheet = false
    @State private var isShowingPatternLookup = false
    @State private var isShowingClearDrawingConfirmation = false
    @State private var isShowingResetCounterConfirmation = false
    @State private var isShowingUnlinkPatternConfirmation = false
    @State private var isShowingCompletionPrompt = false
    @State private var isShowingCurrentRowEditor = false
    @State private var isShowingTargetRowEditor = false
    @State private var isShowingCounterMemoEditor = false
    @State private var isShowingYarnUsageSheet = false
    @State private var isShowingWorkSessionList = false
    @State private var isCounterSheetExpanded = false
    @State private var editingYarnUsage: ProjectYarnUsage?
    @State private var rowInstructionSheet: RowInstructionSheet?
    @State private var pendingPatternFileImport: PendingPatternFileImport?
    @State private var rowInstructionPendingDeletion: RowInstruction?
    @State private var yarnUsagePendingDeletion: ProjectYarnUsage?
    @State private var selectedLearningSkill: Skill?
    @State private var manualPatternTitle = ""
    @State private var sectionNameText = ""
    @State private var counterMemoText = ""
    @State private var yarnUsageQuantity = 1
    @State private var yarnUsageMemo = ""

    private let dictionaryRepository: (any DictionaryRepository)?
    private let skillRepository: (any SkillRepository)?

    init(
        viewModel: ProjectWorkspaceViewModel,
        initialTab: WorkspaceTab = .working,
        dictionaryRepository: (any DictionaryRepository)? = nil,
        skillRepository: (any SkillRepository)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = State(initialValue: initialTab)
        self.dictionaryRepository = dictionaryRepository
        self.skillRepository = skillRepository
    }

    var body: some View {
        mainLayout
            .warmScreenBackground()
            .toolbar(.hidden, for: .tabBar)
        .navigationTitle("작업 공간")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    isShowingEditProject = true
                }
                .accessibilityIdentifier(AppAccessibilityID.Workspace.editProjectButton)
            }
        }
        .sheet(isPresented: $isShowingEditProject) {
            EditProjectView(
                project: viewModel.project,
                onSave: { formData in
                    await viewModel.updateProject(with: formData)
                },
                onDelete: {
                    let didDelete = await viewModel.deleteProject()

                    if didDelete {
                        dismiss()
                    }

                    return didDelete
                }
            )
        }
        .fileImporter(
            isPresented: $isShowingDirectPatternImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleDirectPatternImporterResult(result)
        }
        .sheet(isPresented: $isShowingLibraryPicker) {
            PatternSelectionView(patterns: viewModel.availablePatterns) { pattern in
                Task {
                    await viewModel.attachPatternFromLibrary(pattern)
                }
            }
        }
        .sheet(isPresented: $isShowingPDFViewer) {
            NavigationStack {
                Group {
                    if let fileURL = viewModel.attachedPatternFileURL {
                        PDFKitView(
                            url: fileURL,
                            highlightTerms: viewModel.relatedSkills.map(\.abbreviation)
                        )
                    } else {
                        unavailablePDFView
                    }
                }
                .navigationTitle(viewModel.project.patternCopy?.titleSnapshot ?? "도안")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("완료") {
                            isShowingPDFViewer = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingManualPatternSheet) {
            ManualPatternSheet(
                title: $manualPatternTitle,
                saveAction: {
                    let didSave = await viewModel.attachManualPattern(title: manualPatternTitle)
                    if didSave {
                        manualPatternTitle = ""
                    }
                    return didSave
                }
            )
        }
        .sheet(isPresented: $isShowingPatternDocumentScanner) {
            DocumentScannerView { result in
                isShowingPatternDocumentScanner = false
                handleScannedPatternResult(result)
            }
        }
        .sheet(item: $pendingPatternFileImport) { pendingImport in
            PatternImportStorageDecisionSheet(
                pendingImport: pendingImport,
                storeAction: {
                    attachPendingPatternFile(pendingImport, storeInLibrary: true)
                },
                projectOnlyAction: {
                    attachPendingPatternFile(pendingImport, storeInLibrary: false)
                },
                cancelAction: {
                    pendingPatternFileImport = nil
                }
            )
        }
        .sheet(isPresented: $isShowingPatternLookup) {
            if let dictionaryRepository, let skillRepository {
                PatternSupportLookupView(
                    dictionaryRepository: dictionaryRepository,
                    skillRepository: skillRepository
                )
            } else {
                NavigationStack {
                    EmptyStateView(
                        title: "사전/스킬을 열 수 없어요.",
                        description: "작업공간에 사전과 스킬 저장소가 연결되어 있지 않아요.",
                        systemImage: "text.magnifyingglass"
                    )
                    .padding()
                    .warmScreenBackground()
                    .navigationTitle("도안 보며 찾아보기")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(item: $selectedLearningSkill) { skill in
            NavigationStack {
                if let dictionaryRepository, let skillRepository {
                    WorkspaceSkillLearningView(
                        skill: skill,
                        skillRepository: skillRepository,
                        dictionaryRepository: dictionaryRepository
                    )
                } else {
                    SkillDetailView(skill: skill)
                }
            }
        }
        .sheet(item: $rowInstructionSheet) { sheet in
            rowInstructionSheetView(sheet)
        }
        .sheet(isPresented: $isShowingCurrentRowEditor) {
            NumberEditSheet(
                title: "현재 단수 수정",
                message: "현재 단수를 숫자로 입력해 주세요.",
                initialValue: viewModel.currentRow
            ) { value in
                Task {
                    await viewModel.updateCurrentRow(value)
                    presentCompletionPromptIfNeeded()
                }
            }
        }
        .sheet(isPresented: $isShowingTargetRowEditor) {
            NumberEditSheet(
                title: "총 단수 설정",
                message: "0은 총 단수 미설정을 의미해요.",
                initialValue: viewModel.rowCounter.targetRow ?? 0
            ) { value in
                Task {
                    await viewModel.updateTargetRow(value)
                    presentCompletionPromptIfNeeded()
                }
            }
        }
        .sheet(isPresented: $isShowingCounterMemoEditor) {
            CounterMemoEditSheet(
                memo: $counterMemoText,
                saveAction: {
                    Task {
                        await viewModel.updateCounterMemo(counterMemoText)
                        isShowingCounterMemoEditor = false
                    }
                }
            )
        }
        .sheet(isPresented: $isShowingWorkSessionList) {
            ProjectWorkSessionListView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingYarnUsageSheet) {
            YarnUsageRecordSheet(
                title: editingYarnUsage == nil ? "실 사용 기록" : "실 사용 수정",
                yarnName: viewModel.project.yarnSummaryText ?? "연결된 실",
                maxQuantity: maxYarnUsageQuantity,
                cancelAction: {
                    isShowingYarnUsageSheet = false
                    editingYarnUsage = nil
                },
                saveAction: { quantity, memo in
                    Task {
                        let didRecord: Bool
                        if let editingYarnUsage {
                            didRecord = await viewModel.updateYarnUsage(
                                editingYarnUsage,
                                quantityUsed: quantity,
                                memo: memo
                            )
                        } else {
                            didRecord = await viewModel.recordYarnUsage(
                                quantityUsed: quantity,
                                memo: memo
                            )
                        }

                        if didRecord {
                            isShowingYarnUsageSheet = false
                            editingYarnUsage = nil
                        }
                    }
                },
                quantity: $yarnUsageQuantity,
                memo: $yarnUsageMemo
            )
        }
        .alert("실 사용 기록을 삭제할까요?", isPresented: yarnUsageDeletionBinding) {
            Button("취소", role: .cancel) {
                yarnUsagePendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                if let usage = yarnUsagePendingDeletion {
                    Task {
                        let didDelete = await viewModel.deleteYarnUsage(usage)
                        if LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: didDelete) {
                            yarnUsagePendingDeletion = nil
                        }
                    }
                }
            }
        } message: {
            Text("삭제하면 차감했던 실 수량이 다시 복구돼요.")
        }
        .alert("그리기를 지울까요?", isPresented: $isShowingClearDrawingConfirmation) {
            Button("취소", role: .cancel) {
            }

            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.clearDrawingData()
                }
            }
        } message: {
            Text("저장된 그리기 메모는 복구할 수 없어요.")
        }
        .alert("도안 연결을 해제할까요?", isPresented: $isShowingUnlinkPatternConfirmation) {
            Button("취소", role: .cancel) {
            }

            Button("연결 해제", role: .destructive) {
                Task {
                    await viewModel.unlinkPattern()
                }
            }
        } message: {
            Text("이 프로젝트에서 도안 연결만 해제돼요. 도안 창고의 원본은 삭제되지 않아요.")
        }
        .alert("단수를 리셋할까요?", isPresented: $isShowingResetCounterConfirmation) {
            Button("취소", role: .cancel) {
            }

            Button("리셋", role: .destructive) {
                Task {
                    await viewModel.resetCurrentRow()
                }
            }
        } message: {
            Text("현재 단수가 0단으로 돌아가요. 행안내 내용은 유지돼요.")
        }
        .alert("목표 단수에 도달했어요", isPresented: $isShowingCompletionPrompt) {
            Button("완료로 변경") {
                Task {
                    await viewModel.completeProject()
                }
            }

            Button("나중에", role: .cancel) {
            }
        } message: {
            Text("프로젝트 상태를 FO - 완성으로 변경할까요?")
        }
        .alert("행안내를 삭제할까요?", isPresented: deleteInstructionBinding) {
            Button("취소", role: .cancel) {
                rowInstructionPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                if let instruction = rowInstructionPendingDeletion {
                    Task {
                        let didDelete = await viewModel.deleteRowInstruction(instruction)
                        if didDelete {
                            rowInstructionPendingDeletion = nil
                        }
                    }
                }
            }
        } message: {
            Text("삭제한 행안내는 되돌릴 수 없어요.")
        }
        .alert("오류", isPresented: errorBinding) {
            Button("확인", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(currentErrorMessage)
        }
        .task {
            sectionNameText = viewModel.rowCounter.sectionName ?? ""
            counterMemoText = viewModel.rowCounter.memo ?? ""
            viewModel.startWorkSession()
            await viewModel.loadRelatedSkills()
            await viewModel.loadDrawingData()
            await viewModel.loadYarnUsage()
            await viewModel.loadNeedles()
            await viewModel.loadTools()
            await viewModel.loadProgressPhotos()
            await viewModel.loadGaugeRecords()

            while !Task.isCancelled {
                viewModel.refreshCurrentSessionElapsed()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        .onDisappear {
            Task {
                await viewModel.finishWorkSession()
            }
        }
    }

    private var workspaceTabPicker: some View {
        Picker("작업 공간 보기", selection: $selectedTab) {
            Text("뜨는 중").tag(WorkspaceTab.working)
            Text("프로젝트 정보").tag(WorkspaceTab.info)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(AppAccessibilityID.Workspace.tabPicker)
    }

    @ViewBuilder
    private var mainLayout: some View {
        if selectedTab == .working {
            patternFocusLayout
        } else {
            scrollLayout
        }
    }

    private var scrollLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                ProjectWorkspaceHeaderView(viewModel: viewModel)
                workspaceTabPicker
                infoTabSections
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }

    private var patternFocusLayout: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ProjectWorkspaceHeaderView(viewModel: viewModel)
                    workspaceTabPicker
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                patternFocusPanel

                Spacer(minLength: 96)
            }

            counterSheet
        }
    }

    private var counterSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppTheme.Color.warmDivider)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if isCounterSheetExpanded {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        counterPanel

                        ProjectWorkTimePanelView(
                            viewModel: viewModel,
                            startAction: {
                                viewModel.startWorkSession()
                            },
                            finishAction: {
                                Task {
                                    await viewModel.finishWorkSession()
                                }
                            },
                            showSessionsAction: {
                                isShowingWorkSessionList = true
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .frame(height: UIScreen.main.bounds.height * 0.58)
            } else {
                compactCounterBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.Color.warmBackground)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    withAnimation(.spring(duration: 0.3)) {
                        if value.translation.height < -40 {
                            isCounterSheetExpanded = true
                        } else if value.translation.height > 40 {
                            isCounterSheetExpanded = false
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private var infoTabSections: some View {
        ProjectWorkspaceSummaryView(viewModel: viewModel)
        ProjectProgressPhotoPanelView(viewModel: viewModel)
        ProjectYarnUsagePanelView(
            viewModel: viewModel,
            recordAction: {
                editingYarnUsage = nil
                yarnUsageQuantity = 1
                yarnUsageMemo = ""
                isShowingYarnUsageSheet = true
            },
            editAction: { usage in
                editingYarnUsage = usage
                yarnUsageQuantity = usage.quantityUsed
                yarnUsageMemo = usage.memo
                isShowingYarnUsageSheet = true
            },
            deleteAction: { usage in
                yarnUsagePendingDeletion = usage
            }
        )
        ProjectNeedlePanelView(viewModel: viewModel)
        ProjectToolPanelView(viewModel: viewModel)
        ProjectGaugeRecordPanelView(viewModel: viewModel)
        ProjectMemoPanelView(
            memoText: $viewModel.memoText,
            hasUnsavedChanges: viewModel.hasUnsavedMemoChanges,
            saveAction: {
                Task {
                    await viewModel.saveMemo()
                }
            }
        )
        relatedSkillsSection
    }

    private var patternFocusPanel: some View {
        ProjectPatternFocusView(
            viewModel: viewModel,
            directImportAction: {
                isShowingDirectPatternImporter = true
            },
            scanAction: {
                isShowingPatternDocumentScanner = true
            },
            libraryAction: {
                Task { @MainActor in
                    await viewModel.loadAvailablePatterns()
                    isShowingLibraryPicker = true
                }
            },
            manualInputAction: {
                manualPatternTitle = viewModel.project.patternCopy?.titleSnapshot ?? ""
                isShowingManualPatternSheet = true
            },
            showPDFAction: {
                isShowingPDFViewer = true
            },
            lookupAction: {
                isShowingPatternLookup = true
            },
            clearDrawingAction: {
                isShowingClearDrawingConfirmation = true
            },
            unlinkAction: {
                isShowingUnlinkPatternConfirmation = true
            }
        )
    }

    private var compactCounterBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                Task {
                    await viewModel.decrementRow()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.Color.accentSoft, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterPreviousButton)
            .disabled(viewModel.currentRow == 0)
            .opacity(viewModel.currentRow == 0 ? 0.4 : 1)

            Button {
                isShowingCurrentRowEditor = true
            } label: {
                VStack(spacing: 2) {
                    Text(viewModel.currentRow == 0 ? "시작 전" : "\(viewModel.currentRow)단")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    if let targetRow = viewModel.rowCounter.targetRow {
                        Text("목표 \(targetRow)단")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterEditCurrentButton)

            Button {
                Task {
                    await viewModel.incrementRow()
                    presentCompletionPromptIfNeeded()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.Color.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterNextButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .appCard(cornerRadius: 20)
    }

    private var counterPanel: some View {
        ProjectCounterPanelView(
            viewModel: viewModel,
            sectionNameText: $sectionNameText,
            counterMemoText: $counterMemoText,
            counterMode: counterModeBinding,
            decrementAction: {
                Task {
                    await viewModel.decrementRow()
                }
            },
            incrementAction: {
                Task {
                    await viewModel.incrementRow()
                    presentCompletionPromptIfNeeded()
                }
            },
            editCurrentRowAction: {
                isShowingCurrentRowEditor = true
            },
            editTargetRowAction: {
                isShowingTargetRowEditor = true
            },
            saveSectionNameAction: {
                Task {
                    await viewModel.updateCounterSectionName(sectionNameText)
                }
            },
            editMemoAction: {
                counterMemoText = viewModel.rowCounter.memo ?? ""
                isShowingCounterMemoEditor = true
            },
            resetAction: {
                isShowingResetCounterConfirmation = true
            },
            addRowInstructionAction: {
                rowInstructionSheet = .add(defaultRowNumber: defaultRowInstructionNumber)
            },
            bulkAddRowInstructionsAction: {
                rowInstructionSheet = .bulk(defaultStartRowNumber: defaultRowInstructionNumber)
            },
            renumberRowInstructionsAction: {
                Task {
                    await viewModel.renumberRowInstructions()
                }
            },
            addSuggestedRowInstructionAction: { suggestion in
                Task {
                    await viewModel.addRowInstruction(from: suggestion)
                }
            },
            editRowInstructionAction: { instruction in
                rowInstructionSheet = .edit(instruction)
            },
            deleteRowInstructionAction: { instruction in
                rowInstructionPendingDeletion = instruction
            },
            skillTapAction: { tag in
                selectedLearningSkill = tag.skill
            }
        )
    }

    private var relatedSkillsSection: some View {
        WorkspaceSectionView(title: "관련 스킬", systemImage: "graduationcap") {
            if viewModel.relatedSkills.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("아직 연결된 스킬이 없어요.")
                        .foregroundStyle(.secondary)

                    Text("행안내나 메모에 뜨개 약어를 적으면 여기에 표시돼요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.relatedSkills) { skill in
                        Button {
                            selectedLearningSkill = skill
                        } label: {
                            SkillRowView(skill: skill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowInstructionSheetView(_ sheet: RowInstructionSheet) -> some View {
        switch sheet {
        case .add(let defaultRowNumber):
            RowInstructionFormSheet(
                title: "행안내 추가",
                initialRowNumber: defaultRowNumber,
                initialText: "",
                initialSkillTags: ""
            ) { rowNumber, text, skillTags in
                await viewModel.addRowInstruction(
                    rowNumber: rowNumber,
                    text: text,
                    skillTags: skillTags
                )
            }
        case .edit(let instruction):
            RowInstructionFormSheet(
                title: "행안내 수정",
                initialRowNumber: instruction.rowNumber,
                initialText: instruction.instructionText,
                initialSkillTags: instruction.skillTags
            ) { rowNumber, text, skillTags in
                await viewModel.updateRowInstruction(
                    instruction,
                    rowNumber: rowNumber,
                    text: text,
                    skillTags: skillTags
                )
            }
        case .bulk(let defaultStartRowNumber):
            BulkRowInstructionSheet(defaultStartRowNumber: defaultStartRowNumber) { startRowNumber, lines in
                await viewModel.addBulkRowInstructions(
                    startRowNumber: startRowNumber,
                    lines: lines
                )
            }
        }
    }

    private var counterModeBinding: Binding<RowCounterMode> {
        Binding(
            get: { viewModel.rowCounter.mode },
            set: { mode in
                Task {
                    await viewModel.updateCounterMode(mode)
                }
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    private var deleteInstructionBinding: Binding<Bool> {
        Binding(
            get: { rowInstructionPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    rowInstructionPendingDeletion = nil
                }
            }
        )
    }

    private var yarnUsageDeletionBinding: Binding<Bool> {
        Binding(
            get: { yarnUsagePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    yarnUsagePendingDeletion = nil
                }
            }
        )
    }

    private var maxYarnUsageQuantity: Int? {
        guard let currentQuantity = viewModel.attachedYarn?.quantity else {
            return nil
        }

        return currentQuantity + (editingYarnUsage?.quantityUsed ?? 0)
    }

    private var defaultRowInstructionNumber: Int {
        if viewModel.currentRow > 0,
           !viewModel.rowCounter.rowInstructions.contains(where: { $0.rowNumber == viewModel.currentRow }) {
            return viewModel.currentRow
        }

        return (viewModel.rowCounter.rowInstructions.map(\.rowNumber).max() ?? 0) + 1
    }

    private var currentErrorMessage: String {
        viewModel.errorMessage ?? ""
    }

    private var unavailablePDFView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("열 수 있는 PDF 파일이 없어요.")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func handleDirectPatternImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let fileURLs):
            guard let fileURL = fileURLs.first else {
                return
            }

            pendingPatternFileImport = PendingPatternFileImport(fileURL: fileURL, source: .file)
        case .failure:
            break
        }
    }

    private func handleScannedPatternResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let fileURL):
            pendingPatternFileImport = PendingPatternFileImport(fileURL: fileURL, source: .scan)
        case .failure:
            break
        }
    }

    private func attachPendingPatternFile(_ pendingImport: PendingPatternFileImport, storeInLibrary: Bool) {
        pendingPatternFileImport = nil
        Task {
            await viewModel.attachNewPattern(
                fromFileAt: pendingImport.fileURL,
                storeInLibrary: storeInLibrary
            )
        }
    }

    private func presentCompletionPromptIfNeeded() {
        guard viewModel.project.status != .fo,
              let targetRow = viewModel.rowCounter.targetRow,
              targetRow > 0,
              viewModel.currentRow >= targetRow
        else {
            return
        }

        isShowingCompletionPrompt = true
    }
}

private enum RowInstructionSheet: Identifiable {
    case add(defaultRowNumber: Int)
    case edit(RowInstruction)
    case bulk(defaultStartRowNumber: Int)

    var id: String {
        switch self {
        case .add(let rowNumber):
            return "add-\(rowNumber)"
        case .edit(let instruction):
            return "edit-\(instruction.id.uuidString)"
        case .bulk(let rowNumber):
            return "bulk-\(rowNumber)"
        }
    }
}

private struct PendingPatternFileImport: Identifiable {
    let id = UUID()
    let fileURL: URL
    let source: PatternFileImportSource
}

private enum PatternFileImportSource {
    case file
    case scan

    var description: String {
        switch self {
        case .file:
            return "선택한 PDF"
        case .scan:
            return "스캔한"
        }
    }
}

private struct PatternImportStorageDecisionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let pendingImport: PendingPatternFileImport
    let storeAction: () -> Void
    let projectOnlyAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                AppDetailHeaderView(
                    title: "도안창고에 보관할까요?",
                    subtitle: pendingImport.fileURL.lastPathComponent,
                    systemImage: pendingImport.source.systemImage,
                    tint: AppTheme.Color.accent
                )

                AppSoftPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("\(pendingImport.source.description) 도안을 프로젝트에 연결합니다.", systemImage: "doc.text")
                            .font(.subheadline.bold())

                        Text("도안 창고에 보관하면 Library에서 다시 가져올 수 있고, 프로젝트에만 연결하면 이 작업공간 사본으로만 사용해요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    dismiss()
                    storeAction()
                } label: {
                    Label("도안창고에 보관하고 연결", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    dismiss()
                    projectOnlyAction()
                } label: {
                    Label("프로젝트에만 연결", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .warmScreenBackground()
            .navigationTitle("도안 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                        cancelAction()
                    }
                }
            }
        }
    }
}

private extension PatternFileImportSource {
    var systemImage: String {
        switch self {
        case .file:
            return "doc.badge.plus"
        case .scan:
            return "doc.viewfinder"
        }
    }
}

private struct ManualPatternSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var title: String
    let saveAction: () async -> Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "수동 도안",
                        description: "도안 창고에 없는 도안 이름을 프로젝트에 직접 연결해요.",
                        systemImage: "doc.badge.plus",
                        tint: AppTheme.Color.accent
                    ) {
                        AppFormTextFieldRow(
                            title: "도안 이름",
                            placeholder: "예: 직접 입력한 도안",
                            systemImage: "textformat",
                            text: $title,
                            identifier: AppAccessibilityID.Workspace.patternManualTitleField
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle("수동 입력")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.patternManualSaveButton
                ) {
                    Task {
                        let didSave = await saveAction()
                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
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

private struct NumberEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let initialValue: Int
    let saveAction: (Int) -> Void
    @State private var valueText: String

    init(
        title: String,
        message: String,
        initialValue: Int,
        saveAction: @escaping (Int) -> Void
    ) {
        self.title = title
        self.message = message
        self.initialValue = initialValue
        self.saveAction = saveAction
        _valueText = State(initialValue: "\(initialValue)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "숫자 설정",
                        description: message,
                        systemImage: "number",
                        tint: AppTheme.Color.accent
                    ) {
                        AppFormTextFieldRow(
                            title: title,
                            placeholder: "0",
                            systemImage: "textformat.123",
                            text: $valueText,
                            identifier: AppAccessibilityID.Workspace.counterNumberField
                        )
                        .keyboardType(.numberPad)
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
                    isDisabled: false,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.counterNumberSaveButton
                ) {
                    saveAction(Int(valueText) ?? initialValue)
                    dismiss()
                }
            }
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

private struct CounterMemoEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var memo: String
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "카운터 메모",
                        description: "현재 행에서 기억해야 할 실수 방지 메모를 남겨요.",
                        systemImage: "note.text",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextEditorRow(
                            title: "메모",
                            placeholder: "예: 다음 단에서 감아뜨기 시작",
                            systemImage: "pencil.line",
                            text: $memo,
                            minHeight: 150,
                            identifier: AppAccessibilityID.Workspace.counterMemoField
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle("카운터 메모")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: false,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.counterMemoSaveButton
                ) {
                    saveAction()
                    dismiss()
                }
            }
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

struct WorkspaceSkillLearningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var animationViewModel: SkillAnimationViewModel
    @StateObject private var dictionaryViewModel: DictionaryViewModel

    let skill: Skill

    init(
        skill: Skill,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository
    ) {
        self.skill = skill
        _animationViewModel = StateObject(
            wrappedValue: SkillAnimationViewModel(skillRepository: skillRepository)
        )
        _dictionaryViewModel = StateObject(
            wrappedValue: DictionaryViewModel(dictionaryRepository: dictionaryRepository)
        )
    }

    var body: some View {
        SkillAnimationDetailView(
            skill: resolvedSkill,
            viewModel: animationViewModel,
            dictionaryViewModel: dictionaryViewModel,
            dictionaryTerms: dictionaryViewModel.terms,
            allSkills: allSkills,
            skillAnimations: animationViewModel.skillAnimations
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("완료") {
                    dismiss()
                }
            }
        }
        .task {
            await animationViewModel.loadSkills()
            await dictionaryViewModel.loadTerms()
        }
    }

    private var resolvedSkill: Skill {
        animationViewModel.skills.first { $0.id == skill.id } ?? skill
    }

    private var allSkills: [Skill] {
        animationViewModel.skills.isEmpty ? [resolvedSkill] : animationViewModel.skills
    }
}

private struct RowInstructionFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let saveAction: (Int, String, String) async -> Bool
    @State private var rowNumberText: String
    @State private var instructionText: String
    @State private var skillTags: String

    init(
        title: String,
        initialRowNumber: Int,
        initialText: String,
        initialSkillTags: String,
        saveAction: @escaping (Int, String, String) async -> Bool
    ) {
        self.title = title
        self.saveAction = saveAction
        _rowNumberText = State(initialValue: "\(initialRowNumber)")
        _instructionText = State(initialValue: initialText)
        _skillTags = State(initialValue: initialSkillTags)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "행",
                        description: "도안에서 안내가 필요한 행 번호를 지정해요.",
                        systemImage: "number",
                        tint: AppTheme.Color.accent
                    ) {
                        AppFormTextFieldRow(
                            title: "행 번호",
                            placeholder: "1",
                            systemImage: "textformat.123",
                            text: $rowNumberText,
                            identifier: AppAccessibilityID.Workspace.rowInstructionNumberField
                        )
                        .keyboardType(.numberPad)
                    }

                    AppFormSection(
                        title: "안내",
                        description: "행 카운터에서 바로 볼 수 있는 작업 지시를 입력해요.",
                        systemImage: "list.bullet.rectangle",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextEditorRow(
                            title: "행 안내",
                            placeholder: "예: 12코 겉뜨기, 마커 전 2코 모아뜨기",
                            systemImage: "text.alignleft",
                            text: $instructionText,
                            minHeight: 130,
                            identifier: AppAccessibilityID.Workspace.rowInstructionTextField
                        )
                    }

                    AppFormSection(
                        title: "스킬 태그",
                        description: "도안을 보다가 바로 찾아볼 수 있게 약어를 연결해요.",
                        systemImage: "tag",
                        tint: AppTheme.Color.softAccent
                    ) {
                        AppFormTextFieldRow(
                            title: "약어",
                            placeholder: "예: K, P, YO",
                            systemImage: "textformat.abc",
                            text: $skillTags,
                            identifier: AppAccessibilityID.Workspace.rowInstructionSkillTagsField
                        )
                        .textInputAutocapitalization(.characters)
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
                    isDisabled: instructionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.rowInstructionSaveButton
                ) {
                    Task {
                        let didSave = await saveAction(
                            Int(rowNumberText) ?? 0,
                            instructionText,
                            skillTags
                        )
                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
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

private struct BulkRowInstructionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let defaultStartRowNumber: Int
    let saveAction: (Int, String) async -> Bool
    @State private var startRowNumberText: String
    @State private var lines = ""

    init(
        defaultStartRowNumber: Int,
        saveAction: @escaping (Int, String) async -> Bool
    ) {
        self.defaultStartRowNumber = defaultStartRowNumber
        self.saveAction = saveAction
        _startRowNumberText = State(initialValue: "\(defaultStartRowNumber)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "시작 행",
                        description: "붙여넣은 첫 줄이 어느 행인지 지정해요.",
                        systemImage: "number",
                        tint: AppTheme.Color.accent
                    ) {
                        AppFormTextFieldRow(
                            title: "시작 행 번호",
                            placeholder: "1",
                            systemImage: "textformat.123",
                            text: $startRowNumberText,
                            identifier: AppAccessibilityID.Workspace.bulkRowInstructionStartField
                        )
                        .keyboardType(.numberPad)
                    }

                    AppFormSection(
                        title: "행안내",
                        description: "한 줄이 한 행안내로 등록돼요.",
                        systemImage: "text.badge.plus",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormTextEditorRow(
                            title: "붙여넣기",
                            placeholder: "1행 안내\n2행 안내\n3행 안내",
                            systemImage: "text.alignleft",
                            text: $lines,
                            minHeight: 200,
                            identifier: AppAccessibilityID.Workspace.bulkRowInstructionLinesField
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle("여러 줄 붙여넣기")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: lines.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.bulkRowInstructionSaveButton
                ) {
                    Task {
                        let didSave = await saveAction(
                            Int(startRowNumberText) ?? defaultStartRowNumber,
                            lines
                        )
                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
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
        ProjectWorkspaceView(
            viewModel: ProjectWorkspaceViewModel(
                project: SampleData.projects[0],
                projectRepository: AppRepositoryContainer.shared.projectRepository,
                patternRepository: AppRepositoryContainer.shared.patternRepository,
                skillRepository: AppRepositoryContainer.shared.skillRepository,
                libraryRepository: AppRepositoryContainer.shared.libraryRepository,
                gaugeRecordRepository: AppRepositoryContainer.shared.gaugeRecordRepository
            )
        )
    }
}
