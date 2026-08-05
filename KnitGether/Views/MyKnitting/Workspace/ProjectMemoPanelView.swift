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
            TextEditor(text: $memoText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier(AppAccessibilityID.Workspace.projectMemoField)
        }
    }
}
