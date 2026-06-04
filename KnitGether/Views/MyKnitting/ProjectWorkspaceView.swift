//
//  ProjectWorkspaceView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingEditProject = false
    @State private var isShowingDirectPatternImporter = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingPDFViewer = false
    @State private var isShowingClearDrawingConfirmation = false

    init(viewModel: ProjectWorkspaceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                patternBackground
                    .frame(width: proxy.size.width, height: proxy.size.height)

                DraggableBottomSheet(position: sheetPositionBinding) {
                    sheetHeader
                } content: {
                    sheetContent
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("작업 공간")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    isShowingEditProject = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditProject) {
            EditProjectView(
                project: viewModel.project,
                onSave: { formData in
                    Task {
                        await viewModel.updateProject(with: formData)
                    }
                },
                onDelete: {
                    Task {
                        let didDelete = await viewModel.deleteProject()

                        if didDelete {
                            dismiss()
                        }
                    }
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
                        PDFKitView(url: fileURL)
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
        .task {
            viewModel.startWorkSession()
            await viewModel.loadRelatedSkills()
            await viewModel.loadDrawingData()

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

    private var sheetPositionBinding: Binding<ProjectWorkspaceSheetPosition> {
        Binding(
            get: { viewModel.sheetPosition },
            set: { position in
                Task {
                    await viewModel.updateSheetPosition(position)
                }
            }
        )
    }

    private var patternBackground: some View {
        VStack(spacing: 0) {
            projectHeader
            Divider()

            ZStack(alignment: .topLeading) {
                patternViewer
                patternOverlay
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.project.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    StatusBadgeView(status: viewModel.project.status)
                }

                Spacer()

                Image(systemName: viewModel.project.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(viewModel.project.isFavorite ? .yellow : .secondary)
                    .accessibilityLabel(viewModel.project.isFavorite ? "즐겨찾기" : "즐겨찾기 아님")
            }

            HStack(spacing: 14) {
                metadata(title: "시작일", value: formattedDate(viewModel.project.startDate))
                metadata(title: "최근 작업", value: formattedDate(viewModel.project.lastWorkedAt))
                metadata(title: "총 작업 시간", value: formattedDuration(viewModel.project.totalWorkTime))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var patternViewer: some View {
        if let fileURL = viewModel.attachedPatternFileURL {
            ZStack {
                PDFKitView(url: fileURL)
                    .allowsHitTesting(viewModel.interactionMode == .viewer)

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
                }
            }
            .background(Color(.secondarySystemBackground))
        } else if let patternCopy = viewModel.project.patternCopy {
            VStack(spacing: 14) {
                Image(systemName: "doc.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text(patternCopy.titleSnapshot)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("PDF 파일이 연결되지 않았어요.")
                    .foregroundStyle(.secondary)

                if viewModel.interactionMode == .drawing {
                    Text("그리기 모드는 PDF 파일이 연결된 도안에서 사용할 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
        } else {
            VStack(spacing: 14) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("도안 없음")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("도안을 추가하거나 Library에서 가져오면 이 영역에서 볼 수 있어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if viewModel.interactionMode == .drawing {
                    Text("그리기 전에 도안이 필요해요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
        }
    }

    private var patternOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.project.patternCopy?.titleSnapshot ?? "도안")
                        .font(.headline)
                        .lineLimit(1)

                    if let patternCopy = viewModel.project.patternCopy {
                        Label("도안 있음", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)

                        if let fileName = patternCopy.fileNameSnapshot {
                            Text(fileName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Label("도안 없음", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    isShowingPDFViewer = true
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.attachedPatternFileURL == nil)
                .accessibilityLabel("도안 보기")
            }

            Picker("도안 모드", selection: $viewModel.interactionMode) {
                ForEach(PatternInteractionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.interactionMode == .drawing {
                HStack(spacing: 10) {
                    Label("도안 위에 자유롭게 표시할 수 있어요.", systemImage: "pencil.tip")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(role: .destructive) {
                        isShowingClearDrawingConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.drawingData == nil || viewModel.project.patternCopy == nil)
                }
            }

            patternActionButtons
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private var patternActionButtons: some View {
        HStack {
            Button {
                isShowingDirectPatternImporter = true
            } label: {
                Label("도안 추가", systemImage: "plus")
            }

            Button {
                Task { @MainActor in
                    await viewModel.loadAvailablePatterns()
                    isShowingLibraryPicker = true
                }
            } label: {
                Label("Library에서 가져오기", systemImage: "books.vertical")
            }
        }
        .buttonStyle(.bordered)
        .font(.caption)
    }

    @ViewBuilder
    private var sheetHeader: some View {
        if viewModel.sheetPosition == .collapsed {
            HStack(spacing: 8) {
                Text("현재 단수")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.currentRow)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()

                Spacer()
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if viewModel.sheetPosition == .collapsed {
            EmptyView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sheetSection(title: "단수 카운터", systemImage: "number.square") {
                        rowCounterControls(isProminent: viewModel.sheetPosition == .expanded)
                    }

                    sheetSection(title: "작업 시간", systemImage: "timer") {
                        workTimeContent
                    }

                    sheetSection(title: "작업 메모", systemImage: "note.text") {
                        memoContent
                    }

                    if viewModel.sheetPosition == .expanded {
                        sheetSection(title: "관련 스킬", systemImage: "graduationcap") {
                            relatedSkillsContent
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
    }

    private func sheetSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowCounterControls(isProminent: Bool) -> some View {
        HStack(spacing: isProminent ? 24 : 18) {
            Button {
                Task {
                    await viewModel.decrementRow()
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: isProminent ? 60 : 40))
                    .frame(width: isProminent ? 78 : 52, height: isProminent ? 78 : 52)
                    .contentShape(Rectangle())
            }
            .disabled(viewModel.currentRow == 0)
            .accessibilityLabel("단수 줄이기")

            VStack(spacing: isProminent ? 8 : 4) {
                Text("현재 단수")
                    .font(isProminent ? .subheadline : .caption)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.currentRow)")
                    .font(.system(size: isProminent ? 92 : 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            Button {
                Task {
                    await viewModel.incrementRow()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: isProminent ? 60 : 40))
                    .frame(width: isProminent ? 78 : 52, height: isProminent ? 78 : 52)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("단수 늘리기")
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .padding(.vertical, isProminent ? 18 : 8)
    }

    private var workTimeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이번 작업 시간")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedDuration(viewModel.currentSessionElapsed))
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("총 작업 시간")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedDuration(viewModel.project.totalWorkTime))
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }

            Label(
                viewModel.isTrackingTime ? "작업 시간을 기록 중이에요." : "작업 시간이 기록되지 않고 있어요.",
                systemImage: viewModel.isTrackingTime ? "record.circle" : "pause.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var memoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $viewModel.memoText)
                .frame(minHeight: viewModel.sheetPosition == .expanded ? 140 : 92)
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                Task {
                    await viewModel.saveMemo()
                }
            } label: {
                Label("저장", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.hasUnsavedMemoChanges)
        }
    }

    @ViewBuilder
    private var relatedSkillsContent: some View {
        if viewModel.relatedSkills.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("아직 연결된 스킬이 없어요.")
                    .foregroundStyle(.secondary)

                Text("뜨개니게이션에서 도안의 뜨개 용어를 분석해 설명과 애니메이션을 연결할 수 있게 준비합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.relatedSkills) { skill in
                    NavigationLink {
                        SkillDetailView(skill: skill)
                    } label: {
                        SkillRowView(skill: skill)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    private func metadata(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "없음"
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        }

        return "\(seconds)초"
    }

    private func handleDirectPatternImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let fileURLs):
            guard let fileURL = fileURLs.first else {
                return
            }

            Task {
                await viewModel.attachNewPattern(fromFileAt: fileURL)
            }
        case .failure:
            break
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
                skillRepository: AppRepositoryContainer.shared.skillRepository
            )
        )
    }
}
