import SwiftUI

struct ProjectGaugeRecordPanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingPicker = false
    @State private var recordPendingUnlink: GaugeRecord?
    @State private var recordPendingDeletion: GaugeRecord?

    var body: some View {
        WorkspaceSectionView(title: "게이지 기록", systemImage: "function") {
            VStack(alignment: .leading, spacing: 14) {
                AppSoftPanel {
                    header
                }

                if let comparison = viewModel.linkedGaugeWashComparison {
                    washComparisonView(comparison)
                }

                if viewModel.linkedGaugeRecords.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.linkedGaugeRecords) { record in
                            gaugeRecordRow(record)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            GaugeRecordPickerSheet(viewModel: viewModel)
        }
        .alert("게이지 기록 연결을 해제할까요?", isPresented: unlinkBinding) {
            Button("취소", role: .cancel) {
                recordPendingUnlink = nil
            }

            Button("연결 해제", role: .destructive) {
                if let recordPendingUnlink {
                    Task {
                        let didUnlink = await viewModel.unlinkGaugeRecord(recordPendingUnlink)
                        if didUnlink {
                            self.recordPendingUnlink = nil
                        }
                    }
                }
            }
        } message: {
            Text("기록은 삭제되지 않고 프로젝트 연결만 해제돼요.")
        }
        .alert("게이지 기록을 삭제할까요?", isPresented: deletionBinding) {
            Button("취소", role: .cancel) {
                recordPendingDeletion = nil
            }

            Button("삭제", role: .destructive) {
                if let recordPendingDeletion {
                    Task {
                        let didDelete = await viewModel.deleteGaugeRecord(recordPendingDeletion)
                        if didDelete {
                            self.recordPendingDeletion = nil
                        }
                    }
                }
            }
        } message: {
            Text("삭제한 게이지 기록은 복구할 수 없어요.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.linkedGaugeRecords.count)개 연결됨")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("게이지 계산기에서 저장한 세탁 전/후 기록을 프로젝트에 연결해요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button {
                isShowingPicker = true
            } label: {
                Label("연결", systemImage: "link")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(AppAccessibilityID.Workspace.gaugeRecordLinkButton)
            .disabled(viewModel.availableGaugeRecordsForLinking.isEmpty)
        }
    }

    private var emptyState: some View {
        AppSoftPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("연결된 게이지 기록이 없어요.", systemImage: "function")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(viewModel.availableGaugeRecordsForLinking.isEmpty ? "게이지 계산기에서 기록을 저장한 뒤 연결할 수 있어요." : "기존 게이지 기록을 이 프로젝트에 연결해보세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func washComparisonView(_ comparison: GaugeWashComparison) -> some View {
        HStack(spacing: 12) {
            comparisonItem(
                title: "10cm 코 변화",
                value: formattedSignedDecimal(comparison.stitchDeltaPer10Cm)
            )
            comparisonItem(
                title: "10cm 단 변화",
                value: formattedSignedDecimal(comparison.rowDeltaPer10Cm)
            )
        }
    }

    private func comparisonItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private func gaugeRecordRow(_ record: GaugeRecord) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.measurementStage.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer(minLength: 12)

                Text(record.measuredAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(formattedDecimal(record.stitchesPer10Cm))코 / \(formattedDecimal(record.rowsPer10Cm))단", systemImage: "ruler")
                Spacer(minLength: 8)
                if !record.needle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(record.needle)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !record.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(record.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .contextMenu {
            Button(role: .destructive) {
                recordPendingUnlink = record
            } label: {
                Label("연결 해제", systemImage: "xmark.circle")
            }

            Button(role: .destructive) {
                recordPendingDeletion = record
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var unlinkBinding: Binding<Bool> {
        Binding(
            get: { recordPendingUnlink != nil },
            set: { isPresented in
                if !isPresented {
                    recordPendingUnlink = nil
                }
            }
        )
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    recordPendingDeletion = nil
                }
            }
        )
    }

    private func formattedDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formattedSignedDecimal(_ value: Double) -> String {
        let formatted = abs(value).formatted(.number.precision(.fractionLength(0...1)))
        if value > 0 {
            return "+\(formatted)"
        }
        if value < 0 {
            return "-\(formatted)"
        }
        return "0"
    }
}

private struct GaugeRecordPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.availableGaugeRecordsForLinking.isEmpty {
                    EmptyStateView(
                        title: "연결할 게이지 기록이 없어요",
                        description: "게이지 계산기에서 프로젝트 미연결 기록을 먼저 저장해 주세요.",
                        systemImage: "function"
                    )
                    .padding()
                } else {
                    List(viewModel.availableGaugeRecordsForLinking) { record in
                        Button {
                            Task {
                                let didLink = await viewModel.linkGaugeRecord(record)
                                if didLink {
                                    dismiss()
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(record.measurementStage.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(record.measuredAt.formatted(.dateTime.month(.abbreviated).day()))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(record.stitchesPer10Cm.formatted(.number.precision(.fractionLength(0...1))))코 / \(record.rowsPer10Cm.formatted(.number.precision(.fractionLength(0...1))))단")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let patternName = record.patternNameSnapshot,
                                   !patternName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(patternName)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowStyle()
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Color.warmBackground)
                }
            }
            .warmScreenBackground()
            .navigationTitle("게이지 기록 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
