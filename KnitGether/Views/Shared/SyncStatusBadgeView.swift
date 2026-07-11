import SwiftUI

struct SyncStatusBadgeView: View {
    let status: SyncStatus

    var body: some View {
        Label(status.displayTitle, systemImage: status.badgeSystemImage)
            .font(.caption2)
            .fontWeight(.semibold)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
            .accessibilityLabel("서버 저장 상태: \(status.displayTitle)")
    }

    private var tint: Color {
        switch status {
        case .synced:
            return .green
        case .localOnly, .pendingUpload:
            return .blue
        case .pendingDelete:
            return .orange
        case .conflict:
            return .red
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(SyncStatus.allCases) { status in
            SyncStatusBadgeView(status: status)
        }
    }
    .padding()
}
