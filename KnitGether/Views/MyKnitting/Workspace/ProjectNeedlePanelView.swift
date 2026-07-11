import SwiftUI

struct ProjectNeedlePanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingPicker = false
    @State private var isShowingUnlinkConfirmation = false

    var body: some View {
        WorkspaceSectionView(title: "사용 바늘", systemImage: "ruler") {
            VStack(alignment: .leading, spacing: 14) {
                if viewModel.project.needleId == nil {
                    emptyState
                } else {
                    linkedNeedleView
                }

                Button {
                    isShowingPicker = true
                } label: {
                    Label(viewModel.project.needleId == nil ? "바늘 연결" : "바늘 변경", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.needleLinkButton)
                .disabled(viewModel.availableNeedles.isEmpty)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            NeedlePickerSheet(viewModel: viewModel)
        }
        .alert("바늘 연결을 해제할까요?", isPresented: $isShowingUnlinkConfirmation) {
            Button("취소", role: .cancel) {}
            Button("연결 해제", role: .destructive) {
                Task {
                    await viewModel.unlinkNeedle()
                }
            }
        } message: {
            Text("프로젝트에서만 연결이 해제되고 바늘 창고 정보는 유지돼요.")
        }
    }

    private var linkedNeedleView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.sageSoft)
                Image(systemName: iconName(for: viewModel.project.needleTypeSnapshot))
                    .font(.title3)
                    .foregroundStyle(AppTheme.Color.sage)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.project.needleNameSnapshot ?? "연결된 바늘")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(needleDetailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button(role: .destructive) {
                isShowingUnlinkConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("바늘 연결 해제")
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private var emptyState: some View {
        AppSoftPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label("아직 연결된 바늘이 없어요.", systemImage: "ruler")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(viewModel.availableNeedles.isEmpty ? "바늘 창고에 바늘을 먼저 추가해 주세요." : "이 프로젝트에 사용하는 바늘을 연결해 두세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var needleDetailText: String {
        [
            viewModel.project.needleTypeSnapshot,
            viewModel.project.needleSizeSnapshot,
            viewModel.project.needleLengthSnapshot
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func iconName(for type: String?) -> String {
        let normalizedType = type?.lowercased() ?? ""
        if normalizedType.contains("circular") || normalizedType.contains("줄") {
            return "circle"
        }
        if normalizedType.contains("double") || normalizedType.contains("dpn") {
            return "line.3.horizontal"
        }
        return "ruler"
    }
}

private struct NeedlePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.availableNeedles.isEmpty {
                    EmptyStateView(
                        title: "등록된 바늘이 없어요",
                        description: "Library의 바늘 창고에서 바늘을 먼저 추가해 주세요.",
                        systemImage: "ruler"
                    )
                    .padding()
                } else {
                    List(viewModel.availableNeedles) { needle in
                        Button {
                            Task {
                                let didAttach = await viewModel.attachNeedle(needle)
                                if didAttach {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if viewModel.project.needleId == needle.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(needle.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Text(needleDetailText(for: needle))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowStyle()
                        .accessibilityIdentifier(AppAccessibilityID.Workspace.needlePickerRow(needle.id))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Color.warmBackground)
                }
            }
            .warmScreenBackground()
            .navigationTitle("바늘 연결")
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

    private func needleDetailText(for needle: Needle) -> String {
        [
            needle.needleType,
            needle.size,
            needle.length
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}
