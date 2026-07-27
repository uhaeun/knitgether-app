import SwiftUI

/// 계정 저장(서버 동기화)이 필요할 때 여러 화면에 반복되던 "…확인이 필요해요 / 다시 시도"
/// 배너를 하나로 모은 컴팩트 컴포넌트. 화면마다 문구와 재시도 동작만 넘긴다.
/// List 안에서 쓰는 화면은 호출부에서 listRow 관련 모디파이어를 붙인다.
struct SyncRetryBanner: View {
    let message: String
    let isRetrying: Bool
    let retryAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Label(message, systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button(action: retryAction) {
                if isRetrying {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .disabled(isRetrying)
        }
        .padding(.vertical, 4)
    }
}
