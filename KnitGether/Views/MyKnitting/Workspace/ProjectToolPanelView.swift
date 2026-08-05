//
//  ProjectToolPanelView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import SwiftUI

struct ProjectToolPanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var isShowingPicker = false
    @State private var toolPendingUnlink: ToolItem?

    var body: some View {
        WorkspaceSectionView(
            title: "사용 도구",
            systemImage: "wrench.and.screwdriver",
            headerAction: {
                WorkspaceHeaderActionButton(
                    systemImage: "plus",
                    label: "도구 연결",
                    isProminent: viewModel.linkedTools.isEmpty,
                    action: { isShowingPicker = true }
                )
                .disabled(viewModel.availableToolsForLinking.isEmpty)
                .opacity(viewModel.availableToolsForLinking.isEmpty ? 0.35 : 1)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.toolLinkButton)
            }
        ) {
            if viewModel.linkedTools.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.linkedTools) { tool in
                        toolRow(tool)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            ToolPickerSheet(viewModel: viewModel)
        }
        .alert("도구 연결을 해제할까요?", isPresented: unlinkConfirmationBinding) {
            Button("취소", role: .cancel) {
                toolPendingUnlink = nil
            }

            Button("연결 해제", role: .destructive) {
                if let tool = toolPendingUnlink {
                    Task {
                        let didUnlink = await viewModel.unlinkTool(tool)
                        if didUnlink {
                            toolPendingUnlink = nil
                        }
                    }
                }
            }
        } message: {
            Text("프로젝트에서만 연결이 해제되고 도구 창고 정보는 유지돼요.")
        }
    }

    private var emptyState: some View {
        AppSoftPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label("아직 연결된 도구가 없어요.", systemImage: "wrench.and.screwdriver")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(viewModel.availableTools.isEmpty ? "도구 창고에 도구를 먼저 추가해 주세요." : "이 프로젝트에 사용하는 도구를 연결해 두세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toolRow(_ tool: ToolItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.amberSoft)
                Image(systemName: iconName(for: tool))
                    .font(.title3)
                    .foregroundStyle(AppTheme.Color.amber)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(tool.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    SyncStatusBadgeView(status: tool.syncStatus)
                }

                Text(tool.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !tool.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(tool.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Button(role: .destructive) {
                toolPendingUnlink = tool
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("도구 연결 해제")
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .accessibilityIdentifier(AppAccessibilityID.Workspace.linkedToolRow(tool.id))
    }

    private var unlinkConfirmationBinding: Binding<Bool> {
        Binding(
            get: { toolPendingUnlink != nil },
            set: { isPresented in
                if !isPresented {
                    toolPendingUnlink = nil
                }
            }
        )
    }

    private func iconName(for tool: ToolItem) -> String {
        let type = tool.type.lowercased()
        if type.contains("마커") || type.contains("marker") {
            return "tag"
        }
        if type.contains("줄자") || type.contains("measure") {
            return "ruler"
        }
        return "wrench.and.screwdriver"
    }
}

private struct ToolPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectWorkspaceViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.availableToolsForLinking.isEmpty {
                    EmptyStateView(
                        title: "연결할 도구가 없어요",
                        description: "Library의 도구 창고에서 도구를 먼저 추가하거나 이미 연결된 도구를 확인해 주세요.",
                        systemImage: "wrench.and.screwdriver"
                    )
                    .padding()
                } else {
                    List(viewModel.availableToolsForLinking) { tool in
                        Button {
                            Task {
                                let didLink = await viewModel.linkTool(tool)
                                if didLink {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.tint)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tool.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Text(tool.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowStyle()
                        .accessibilityIdentifier(AppAccessibilityID.Workspace.toolPickerRow(tool.id))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Color.warmBackground)
                }
            }
            .warmScreenBackground()
            .navigationTitle("도구 연결")
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
