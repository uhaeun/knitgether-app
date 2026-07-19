import SwiftUI

struct GaugeMeasureHubView: View {
    @StateObject private var viewModel: GaugeMeasureViewModel
    @State private var isShowingQuickMeasure = false

    init(repository: any GaugeTargetRepository) {
        _viewModel = StateObject(wrappedValue: GaugeMeasureViewModel(repository: repository))
    }

    var body: some View {
        List {
            Section {
                Button {
                    isShowingQuickMeasure = true
                } label: {
                    Label("빠른 측정 시작", systemImage: "bolt.fill")
                }
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeQuickMeasureButton)

                NavigationLink {
                    GaugeTargetListView(viewModel: viewModel)
                } label: {
                    Label("목표 게이지와 스와치", systemImage: "target")
                }
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetListLink)
            }
            .listRowStyle()

            if let statusMessage = viewModel.statusMessage {
                Section {
                    AppFormStatusBanner(message: statusMessage)
                }
                .listRowStyle()
            }

            Section("최근 목표 게이지") {
                if viewModel.targets.isEmpty {
                    EmptyStateView(
                        title: "저장된 목표 게이지가 없어요.",
                        description: "빠른 측정이나 목표 게이지 추가로 스와치 기록을 시작할 수 있어요.",
                        systemImage: "target"
                    )
                    .listRowStyle()
                } else {
                    ForEach(viewModel.targets.prefix(5)) { target in
                        NavigationLink {
                            GaugeTargetDetailView(viewModel: viewModel, targetID: target.id)
                        } label: {
                            GaugeTargetSummaryRow(target: target)
                        }
                        .buttonStyle(.plain)
                        .listRowStyle()
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetRow(target.id))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("게이지 측정")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .sheet(isPresented: $isShowingQuickMeasure) {
            NavigationStack {
                QuickMeasureFlowView(isPresented: $isShowingQuickMeasure, viewModel: viewModel)
            }
        }
        .alert("게이지 측정", isPresented: errorBinding) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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
}

struct GaugeTargetListView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    @State private var isShowingTargetForm = false
    @State private var targetPendingDeletion: GaugeTarget?

    var body: some View {
        List {
            if let statusMessage = viewModel.statusMessage {
                AppFormStatusBanner(message: statusMessage)
                    .listRowStyle()
            }

            if viewModel.targets.isEmpty {
                EmptyStateView(
                    title: "목표 게이지가 없어요.",
                    description: "도안이나 직접 입력한 기준 게이지를 목표로 저장해 보세요.",
                    systemImage: "target"
                )
                .listRowStyle()
            }

            ForEach(viewModel.targets) { target in
                NavigationLink {
                    GaugeTargetDetailView(viewModel: viewModel, targetID: target.id)
                } label: {
                    GaugeTargetSummaryRow(target: target)
                }
                .buttonStyle(.plain)
                .listRowStyle()
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetRow(target.id))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        targetPendingDeletion = target
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("목표 게이지")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.prepareTargetForm(for: nil)
                    isShowingTargetForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("목표 게이지 추가")
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetAddButton)
            }
        }
        .sheet(isPresented: $isShowingTargetForm) {
            NavigationStack {
                GaugeTargetFormView(viewModel: viewModel)
            }
        }
        .alert("목표 게이지를 삭제할까요?", isPresented: deleteBinding, presenting: targetPendingDeletion) { target in
            Button("취소", role: .cancel) {
                targetPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteTarget(id: target.id)
                    if didDelete {
                        targetPendingDeletion = nil
                    }
                }
            }
        } message: { target in
            Text("\(target.name)을 삭제합니다.")
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { targetPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    targetPendingDeletion = nil
                }
            }
        )
    }
}

struct GaugeTargetDetailView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID

    @State private var isShowingEditTarget = false
    @State private var isShowingAddSwatch = false

    var body: some View {
        Group {
            if let target = viewModel.target(id: targetID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let statusMessage = viewModel.statusMessage {
                            AppFormStatusBanner(message: statusMessage)
                        }

                        AppDetailHeaderView(
                            title: target.name,
                            subtitle: target.recommendedNeedle,
                            systemImage: "target",
                            tint: AppTheme.Color.accent
                        ) {
                            SyncStatusBadgeView(status: target.syncStatus)
                        }

                        detailSection(title: "목표", systemImage: "target") {
                            GaugeTargetSummaryRow(target: target)

                            if let comparison = GaugeTargetWashComparison(target: target) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("세탁 전/후 비교")
                                        .font(.headline)
                                    detailRow("10cm 코 수 변화", value: signed(comparison.stitchDelta))
                                    detailRow("10cm 단 수 변화", value: signed(comparison.rowDelta))
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        detailSection(title: "스와치", systemImage: "ruler") {
                            if target.swatches.isEmpty {
                                Text("스와치를 추가하면 세탁 전/후 측정값을 비교할 수 있어요.")
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(target.swatches) { swatch in
                                NavigationLink {
                                    SwatchDetailView(
                                        viewModel: viewModel,
                                        targetID: target.id,
                                        swatchID: swatch.id
                                    )
                                } label: {
                                    GaugeSwatchSummaryRow(swatch: swatch)
                                }
                            }

                        Button {
                            viewModel.prepareSwatchForm(for: nil)
                            isShowingAddSwatch = true
                        } label: {
                            Label("스와치 추가", systemImage: "plus")
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeSwatchAddButton)
                        }

                        NavigationLink {
                            GaugeSwatchListView(viewModel: viewModel, targetID: target.id)
                        } label: {
                            HStack {
                                Label("스와치 목록 전체 보기", systemImage: "list.bullet")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.Color.accent.opacity(0.55))
                            }
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .appCard()
                    }
                    .padding()
                }
                .warmScreenBackground()
                .navigationTitle(target.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("편집") {
                            viewModel.prepareTargetForm(for: target)
                            isShowingEditTarget = true
                        }
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeTargetEditButton)
                    }
                }
                .sheet(isPresented: $isShowingEditTarget) {
                    NavigationStack {
                        GaugeTargetFormView(viewModel: viewModel, existingTargetID: target.id)
                    }
                }
                .sheet(isPresented: $isShowingAddSwatch) {
                    NavigationStack {
                        GaugeSwatchFormView(viewModel: viewModel, targetID: target.id)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("목표 게이지를 찾지 못했어요.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .warmScreenBackground()
            }
        }
    }

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(title)

            AppSoftPanel {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
            }
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func signed(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(0...1))))"
    }
}

struct GaugeTargetSummaryRow: View {
    let target: GaugeTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(target.name, systemImage: "target")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                SyncStatusBadgeView(status: target.syncStatus)
            }

            HStack {
                Text("\(formatted(target.targetStitchesPer10Cm))코")

                if let rows = target.targetRowsPer10Cm {
                    Text("\(formatted(rows))단")
                }

                Spacer()

                Text("\(target.swatches.count)개 스와치")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            if let recommendedNeedle = target.recommendedNeedle,
               !recommendedNeedle.isEmpty {
                Text(recommendedNeedle)
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

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct GaugeTargetWashComparison {
    let stitchDelta: Double
    let rowDelta: Double

    init?(target: GaugeTarget) {
        let measurements = target.swatches.flatMap(\.measurements)
        guard
            let before = measurements
                .filter({ $0.washState == .before })
                .max(by: { $0.updatedAt < $1.updatedAt }),
            let after = measurements
                .filter({ $0.washState == .after })
                .max(by: { $0.updatedAt < $1.updatedAt })
        else {
            return nil
        }

        stitchDelta = after.finalStitches - before.finalStitches
        rowDelta = after.finalRows - before.finalRows
    }
}
