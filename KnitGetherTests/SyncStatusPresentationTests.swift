import Testing
@testable import KnitGether

struct SyncStatusPresentationTests {
    @Test func syncStatusProvidesUserFacingKoreanCopy() {
        #expect(SyncStatus.localOnly.displayTitle == "이 기기에만 있음")
        #expect(SyncStatus.pendingUpload.displayTitle == "서버 저장 대기")
        #expect(SyncStatus.synced.displayTitle == "서버 저장됨")
        #expect(SyncStatus.pendingDelete.displayTitle == "삭제 대기")
        #expect(SyncStatus.conflict.displayTitle == "확인 필요")
    }

    @Test func syncStatusProvidesBadgeSystemImages() {
        #expect(SyncStatus.localOnly.badgeSystemImage == "iphone")
        #expect(SyncStatus.pendingUpload.badgeSystemImage == "arrow.triangle.2.circlepath")
        #expect(SyncStatus.synced.badgeSystemImage == "checkmark.icloud.fill")
        #expect(SyncStatus.pendingDelete.badgeSystemImage == "trash")
        #expect(SyncStatus.conflict.badgeSystemImage == "exclamationmark.triangle.fill")
    }

    @Test func syncStatusProvidesUserFacingDetailText() {
        #expect(SyncStatus.localOnly.detailText == "아직 이 기기에만 저장되어 있어요.")
        #expect(SyncStatus.pendingUpload.detailText == "서버 저장을 기다리고 있어요.")
        #expect(SyncStatus.synced.detailText == "현재 계정에 저장되어 있어요.")
        #expect(SyncStatus.pendingDelete.detailText == "서버 삭제 반영을 기다리고 있어요.")
        #expect(SyncStatus.conflict.detailText == "서버 저장 상태 확인이 필요해요.")
    }

    @Test func syncStatusDistinguishesSyncedPendingAndAttentionStates() {
        #expect(!SyncStatus.synced.needsSync)
        #expect(SyncStatus.localOnly.needsSync)
        #expect(SyncStatus.pendingUpload.needsSync)
        #expect(SyncStatus.pendingDelete.needsSync)
        #expect(SyncStatus.conflict.needsUserAttention)
    }
}
