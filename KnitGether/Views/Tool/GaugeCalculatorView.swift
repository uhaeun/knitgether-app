//
//  GaugeCalculatorView.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import SwiftUI
import Combine

struct GaugeCalculatorView: View {
    @StateObject private var viewModel: GaugeCalculatorViewModel
    @ObservedObject private var authSessionStore: AuthSessionStore
    private let gaugeTargetRepository: any GaugeTargetRepository
    @State private var gaugeRecordPendingDeletion: GaugeRecord?
    @State private var isShowingDeleteConfirmation = false

    init(
        authSessionStore: AuthSessionStore,
        gaugeRecordRepository: any GaugeRecordRepository,
        gaugeTargetRepository: any GaugeTargetRepository,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository
    ) {
        self.authSessionStore = authSessionStore
        self.gaugeTargetRepository = gaugeTargetRepository
        _viewModel = StateObject(
            wrappedValue: GaugeCalculatorViewModel(
                gaugeRecordRepository: gaugeRecordRepository,
                gaugeTargetRepository: gaugeTargetRepository,
                projectRepository: projectRepository,
                patternRepository: patternRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !viewModel.availableProjects.isEmpty {
                    AppFormSection(
                        title: "프로젝트 연결",
                        description: "게이지 기록을 특정 프로젝트와 연결해 나중에 작업공간에서 확인해요.",
                        systemImage: "folder",
                        tint: AppTheme.Color.accent
                    ) {
                        Picker("프로젝트", selection: selectedProjectIDBinding) {
                            Text("연결 안 함").tag(Optional<UUID>.none)

                            ForEach(viewModel.availableProjects) { project in
                                Text(project.name).tag(Optional(project.id))
                            }
                        }
                        .padding(.vertical, 12)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeProjectPicker)
                    }
                }

                AppFormSection(
                    title: "도안 연결",
                    description: "도안 창고에서 가져오거나 도안명을 직접 입력할 수 있어요.",
                    systemImage: "doc.text",
                    tint: AppTheme.Color.slate
                ) {
                    if !viewModel.availablePatterns.isEmpty {
                        Picker("도안 창고", selection: selectedPatternIDBinding) {
                            Text("선택 안 함").tag(Optional<UUID>.none)

                            ForEach(viewModel.availablePatterns) { pattern in
                                Text(pattern.title).tag(Optional(pattern.id))
                            }
                        }
                        .padding(.vertical, 12)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugePatternPicker)

                        AppFormDivider()
                    }

                    AppFormTextFieldRow(
                        title: "수동 도안명",
                        placeholder: "도안명 직접 입력",
                        systemImage: "textformat",
                        text: manualPatternNameBinding
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeManualPatternField)

                    AppFormDivider()

                    Text(viewModel.patternConnectionSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "게이지 샘플",
                    description: "실제로 뜬 스와치의 크기와 코/단 수를 입력해요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $viewModel.sampleWidthCm)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSampleWidthField)
                    AppFormDivider()
                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $viewModel.sampleHeightCm)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSampleHeightField)
                    AppFormDivider()
                    AppFormDecimalRow(title: "코 수", systemImage: "circle.grid.cross", text: $viewModel.stitchCount)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSampleStitchesField)
                    AppFormDivider()
                    AppFormDecimalRow(title: "단 수", systemImage: "line.3.horizontal", text: $viewModel.rowCount)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSampleRowsField)
                }

                AppFormSection(
                    title: "목표 크기",
                    description: "완성하고 싶은 크기를 입력하면 필요한 코/단 수를 계산해요.",
                    systemImage: "scope",
                    tint: AppTheme.Color.softAccent
                ) {
                    AppFormDecimalRow(title: "목표 가로(cm)", systemImage: "arrow.left.and.right", text: $viewModel.targetWidthCm)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetWidthField)
                    AppFormDivider()
                    AppFormDecimalRow(title: "목표 세로(cm)", systemImage: "arrow.up.and.down", text: $viewModel.targetHeightCm)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetHeightField)
                }

                AppFormSection(
                    title: "기록",
                    description: "사용 바늘과 메모를 저장 기록에 함께 남겨요.",
                    systemImage: "square.and.pencil",
                    tint: AppTheme.Color.slate
                ) {
                    AppFormTextFieldRow(
                        title: "사용 바늘",
                        placeholder: "예: 4.0mm 대바늘",
                        systemImage: "ruler",
                        text: $viewModel.needle
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeNeedleField)

                    AppFormDivider()

                    AppFormTextEditorRow(
                        title: "메모",
                        placeholder: "메모",
                        systemImage: "note.text",
                        text: $viewModel.memo,
                        minHeight: 96
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMemoField)
                }

                AppFormSection(
                    title: "계산 결과",
                    description: "입력값이 충분하면 10cm 기준 게이지와 필요한 코/단 수를 보여줘요.",
                    systemImage: "function",
                    tint: AppTheme.Color.accent
                ) {
                    resultContent
                        .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "기록 저장",
                    description: "세탁 전/후 기록을 분리해서 저장하고 비교해요.",
                    systemImage: "tray.and.arrow.down",
                    tint: AppTheme.Color.sage
                ) {
                    if let loadedRecord = viewModel.loadedGaugeRecordForEditing {
                        Label("\(loadedRecord.measurementStage.title) 기록 수정 중", systemImage: "pencil")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)

                        AppFormDivider()

                        Button {
                            Task {
                                await viewModel.updateLoadedGaugeRecord()
                            }
                        } label: {
                            Label("불러온 기록 수정 저장", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.result == nil || viewModel.isSavingRecord)
                        .padding(.vertical, 12)

                        AppFormDivider()
                    }

                    Button {
                        Task {
                            await viewModel.saveCurrentGaugeRecord(stage: .beforeWash)
                        }
                    } label: {
                        Label("세탁 전 게이지 저장", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Color.softAccent)
                    .disabled(viewModel.result == nil || viewModel.isSavingRecord)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSaveBeforeButton)

                    AppFormDivider()

                    Button {
                        Task {
                            await viewModel.saveCurrentGaugeRecord(stage: .afterWash)
                        }
                    } label: {
                        Label("세탁 후 게이지 저장", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.result == nil || viewModel.isSavingRecord)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSaveAfterButton)

                    if let statusMessage = viewModel.statusMessage {
                        AppFormDivider()

                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                    }
                }

                AppFormSection(
                    title: "상세 측정",
                    description: "스와치별 측정 흐름을 관리하고 세탁 전/후 목표 게이지를 저장해요.",
                    systemImage: "target",
                    tint: AppTheme.Color.slate
                ) {
                    NavigationLink {
                        GaugeMeasureHubView(repository: gaugeTargetRepository)
                    } label: {
                        Label("스와치 측정 관리", systemImage: "target")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasureHubLink)

                    AppFormDivider()

                    Button {
                        Task {
                            await viewModel.saveCurrentGaugeTarget(washState: .before)
                        }
                    } label: {
                        Label("세탁 전 스와치 측정 저장", systemImage: "ruler")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.result == nil || viewModel.isSavingRecord)
                    .padding(.vertical, 12)

                    AppFormDivider()

                    Button {
                        Task {
                            await viewModel.saveCurrentGaugeTarget(washState: .after)
                        }
                    } label: {
                        Label("세탁 후 스와치 측정 저장", systemImage: "ruler.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.result == nil || viewModel.isSavingRecord)
                    .padding(.vertical, 12)

                    ForEach(Array(viewModel.gaugeTargets.prefix(4))) { target in
                        AppFormDivider()
                        gaugeTargetRow(target)
                            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetRow(target.id))
                            .padding(.vertical, 12)
                    }
                }

                if let comparison = viewModel.washComparison {
                    AppFormSection(
                        title: "세탁 전/후 비교",
                        description: "세탁 후 게이지 변화량을 바로 확인해요.",
                        systemImage: "arrow.left.arrow.right",
                        tint: AppTheme.Color.amber
                    ) {
                        resultRow(
                            "10cm 코 수 변화",
                            value: formattedSignedDecimal(comparison.stitchDeltaPer10Cm)
                        )
                        .padding(.vertical, 12)
                        AppFormDivider()
                        resultRow(
                            "10cm 단 수 변화",
                            value: formattedSignedDecimal(comparison.rowDeltaPer10Cm)
                        )
                        .padding(.vertical, 12)
                    }
                }

                if !viewModel.filteredRecordsForSelectedProject.isEmpty {
                    AppFormSection(
                        title: "최근 게이지 기록",
                        description: "기록을 눌러 다시 불러오거나 길게 눌러 삭제할 수 있어요.",
                        systemImage: "clock.arrow.circlepath",
                        tint: AppTheme.Color.slate
                    ) {
                        ForEach(Array(viewModel.filteredRecordsForSelectedProject.prefix(6))) { record in
                            Button {
                                viewModel.loadGaugeRecord(record)
                            } label: {
                                gaugeRecordRow(record)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 8)
                            .contextMenu {
                                Button(role: .destructive) {
                                    gaugeRecordPendingDeletion = record
                                    isShowingDeleteConfirmation = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(AppTheme.Color.warmBackground.ignoresSafeArea())
        .navigationTitle("게이지 계산기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("초기화") {
                    viewModel.reset()
                }
                .disabled(!viewModel.hasAnyInput)
            }
        }
        .task {
            await viewModel.loadProjects()
            await viewModel.loadPatterns()
            await viewModel.loadGaugeRecords()
            await viewModel.loadGaugeTargets()
        }
        .onReceive(authSessionStore.$currentSession.dropFirst()) { _ in
            Task {
                await viewModel.reloadAfterAccountChange()
            }
        }
        .alert(
            "게이지 계산기",
            isPresented: errorBinding,
            actions: {
                Button("확인") {
                    viewModel.clearError()
                }
            },
            message: {
                Text(viewModel.errorMessage ?? "")
            }
        )
        .alert("게이지 기록을 삭제할까요?", isPresented: $isShowingDeleteConfirmation, presenting: gaugeRecordPendingDeletion) { record in
            Button("취소", role: .cancel) {
                gaugeRecordPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteGaugeRecord(id: record.id)
                    gaugeRecordPendingDeletion = nil
                }
            }
        } message: { record in
            Text("\(record.measurementStage.title) 기록을 삭제합니다.")
        }
    }

    private var selectedProjectIDBinding: Binding<UUID?> {
        Binding(
            get: {
                viewModel.selectedProject?.id
            },
            set: { projectID in
                viewModel.selectedProject = viewModel.availableProjects.first { $0.id == projectID }
            }
        )
    }

    private var selectedPatternIDBinding: Binding<UUID?> {
        Binding(
            get: {
                viewModel.selectedPattern?.id
            },
            set: { patternID in
                let pattern = viewModel.availablePatterns.first { $0.id == patternID }
                viewModel.selectPattern(pattern)
            }
        )
    }

    private var manualPatternNameBinding: Binding<String> {
        Binding(
            get: {
                viewModel.manualPatternName
            },
            set: { name in
                viewModel.setManualPatternName(name)
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

    @ViewBuilder
    private var resultContent: some View {
        if let result = viewModel.result {
            VStack(alignment: .leading, spacing: 18) {
                resultGroup(title: "10cm 기준 게이지") {
                    resultRow("10cm 기준 코 수", value: "\(formattedDecimal(result.stitchesPer10Cm))코")
                    resultRow("10cm 기준 단 수", value: "\(formattedDecimal(result.rowsPer10Cm))단")
                }

                Divider()

                resultGroup(title: "예상 필요 코/단 수") {
                    resultRow("목표 가로에 필요한 코 수", value: "약 \(result.targetStitches)코")
                    resultRow("목표 세로에 필요한 단 수", value: "약 \(result.targetRows)단")
                }
            }
            .padding(.vertical, 6)
        } else {
            Label(viewModel.guidanceMessage, systemImage: "info.circle")
                .foregroundStyle(.secondary)
        }
    }

    private func decimalInputRow(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)

            Spacer()

            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .accessibilityIdentifier(id)
        }
    }

    private func resultGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func gaugeRecordRow(_ record: GaugeRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(record.measurementStage.title, systemImage: "ruler")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(formattedDate(record.measuredAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(formattedDecimal(record.stitchesPer10Cm))코")
                Text("\(formattedDecimal(record.rowsPer10Cm))단")
                Spacer()
                Text("약 \(record.targetStitches)코 · \(record.targetRows)단")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            if let projectName = record.projectNameSnapshot {
                Text(projectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let patternName = record.patternNameSnapshot,
               !patternName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(patternName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private func gaugeTargetRow(_ target: GaugeTarget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(target.name, systemImage: "target")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(formattedDate(target.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(formattedDecimal(target.targetStitchesPer10Cm))코")

                if let rows = target.targetRowsPer10Cm {
                    Text("\(formattedDecimal(rows))단")
                }

                Spacer()

                Text("\(target.swatches.count)개 스와치")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            if let measurement = target.swatches.first?.measurements.first {
                Text("\(measurement.washState.title) · \(measurement.method.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private func formattedDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formattedSignedDecimal(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(formattedDecimal(value))"
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

#Preview {
    NavigationStack {
        GaugeCalculatorView(
            authSessionStore: .shared,
            gaugeRecordRepository: LocalGaugeRecordRepository(),
            gaugeTargetRepository: LocalGaugeTargetRepository(),
            projectRepository: LocalProjectRepository(),
            patternRepository: LocalPatternRepository()
        )
    }
}
