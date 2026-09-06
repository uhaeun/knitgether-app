//
//  WorkTimerSuppressionStore.swift
//  KnitGether
//

import Foundation

/// 사용자가 수동으로 정지한 작업 타이머를 기억한다(원 기획 §13, GitHub #10).
///
/// 작업 화면은 진입할 때 타이머를 자동으로 시작한다. 그래서 사용자가 정지 버튼을 눌러도
/// 화면을 나갔다 돌아오면 다시 돌기 시작했다. 원 기획 §13은 수동 정지한 타이머를 자동으로
/// 재시작하지 않는다고 정하고 있다.
///
/// 억제 상태를 화면 밖에 두는 이유는 수명 때문이다. ProjectWorkspaceViewModel은 화면의
/// @StateObject라 화면을 벗어나면 사라진다. 뷰모델 안에 플래그를 두면 화면을 나가는 순간
/// 함께 없어져서, 정확히 막아야 할 그 순간에 꺼져 있게 된다.
///
/// 앱을 다시 켜면 초기화된다. 프로젝트를 다시 열어 작업을 시작하는 것이 새 세션의 자연스러운
/// 시작점이고, 며칠 전 정지를 앱이 계속 기억하는 편이 오히려 놀랍기 때문이다. 이 범위는
/// 화면 재진입까지 유지한다는 판정에 따른 것이다(2026-09-06).
@MainActor
final class WorkTimerSuppressionStore {
    static let shared = WorkTimerSuppressionStore()

    private var suppressedProjectIds: Set<UUID> = []

    init() {}

    /// 수동 정지를 기록한다. 이후 화면에 다시 들어와도 자동 시작하지 않는다.
    func suppressAutoStart(forProjectId projectId: UUID) {
        suppressedProjectIds.insert(projectId)
    }

    /// 수동 시작을 기록한다. 사용자가 직접 켰으므로 억제를 푼다.
    func allowAutoStart(forProjectId projectId: UUID) {
        suppressedProjectIds.remove(projectId)
    }

    func isAutoStartSuppressed(forProjectId projectId: UUID) -> Bool {
        suppressedProjectIds.contains(projectId)
    }
}
