import SwiftUI

struct SyncStatusBadgeView: View {
    let status: SyncStatus

    @ViewBuilder
    var body: some View {
        // 동기화된 항목은 배지를 숨겨 목록마다 반복되는 시각 노이즈를 줄인다.
        // 저장이 필요한(미동기화) 상태일 때만 표시한다.
        if status != .synced {
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
