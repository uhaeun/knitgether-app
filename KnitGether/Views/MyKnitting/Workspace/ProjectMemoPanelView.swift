import SwiftUI

struct ProjectMemoPanelView: View {
    @Binding var memoText: String
    let hasUnsavedChanges: Bool
    let saveAction: () -> Void

    var body: some View {
        WorkspaceSectionView(
            title: "작업 메모",
            systemImage: "note.text",
            headerAction: {
                WorkspaceHeaderActionButton(
                    systemImage: "checkmark",
                    label: "메모 저장",
                    isProminent: hasUnsavedChanges,
                    action: saveAction
                )
                .disabled(!hasUnsavedChanges)
                .opacity(hasUnsavedChanges ? 1 : 0.35)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.projectMemoSaveButton)
            }
        ) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Spacer()
                    Text("\(memoText.count)/\(AppInputLimit.memo)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                TextEditor(text: $memoText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.projectMemoField)
                    // 타이핑이든 붙여넣기든 상한을 넘는 입력은 잘라낸다 (SPEC-PROJ-01과 같은 UX)
                    .onChange(of: memoText) { newValue in
                        if newValue.count > AppInputLimit.memo {
                            memoText = String(newValue.prefix(AppInputLimit.memo))
                        }
                    }
            }
        }
    }
}
