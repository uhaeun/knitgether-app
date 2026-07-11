import SwiftUI

struct ProjectMemoPanelView: View {
    @Binding var memoText: String
    let hasUnsavedChanges: Bool
    let saveAction: () -> Void

    var body: some View {
        WorkspaceSectionView(title: "작업 메모", systemImage: "note.text") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $memoText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.projectMemoField)

                Button {
                    saveAction()
                } label: {
                    Label("저장", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!hasUnsavedChanges)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.projectMemoSaveButton)
            }
        }
    }
}
