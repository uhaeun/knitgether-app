//
//  LibraryRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

/// 관찰 6: 실, 바늘, 도구의 대표 사진. rawValue는 서버 경로 세그먼트다.
enum LibraryItemPhotoKind: String {
    case yarn = "yarns"
    case needle = "needles"
    case tool = "tools"
}

protocol LibraryRepository {
    func fetchYarns() async throws -> [Yarn]
    func saveYarn(_ yarn: Yarn) async throws
    func deleteYarn(id: UUID) async throws
    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage]
    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage]
    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage
    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage
    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws
    func fetchNeedles() async throws -> [Needle]
    func saveNeedle(_ needle: Needle) async throws
    func deleteNeedle(id: UUID) async throws
    func fetchTools() async throws -> [ToolItem]
    func saveTool(_ tool: ToolItem) async throws
    func deleteTool(id: UUID) async throws
    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem]
    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem
    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws
    // LINK-02 v1.4 다중 연결. 추가 연결은 링크 레코드(연결 시점 스냅샷)로 관리한다.
    /// 창고 항목이 현재 연결된 프로젝트 수. 삭제 확인창의 연결 고지에 쓴다(DEF-25).
    /// 실, 바늘, 도구가 같은 기준(연결)으로 답한다.
    func linkedProjectCount(forYarnId yarnId: UUID) async throws -> Int
    func linkedProjectCount(forNeedleId needleId: UUID) async throws -> Int
    func linkedProjectCount(forToolId toolId: UUID) async throws -> Int

    func fetchYarnLinks(forProjectId projectId: UUID) async throws -> [ProjectYarnLink]
    func linkYarn(_ yarn: Yarn, toProjectId projectId: UUID) async throws -> ProjectYarnLink
    func unlinkYarn(yarnId: UUID, fromProjectId projectId: UUID) async throws
    func fetchNeedleLinks(forProjectId projectId: UUID) async throws -> [ProjectNeedleLink]
    func linkNeedle(_ needle: Needle, toProjectId projectId: UUID) async throws -> ProjectNeedleLink
    func unlinkNeedle(needleId: UUID, fromProjectId projectId: UUID) async throws
    // 대표 사진(관찰 6). v1에서는 온라인 필수 동작이다.
    func uploadLibraryItemPhoto(_ imageData: Data, fileName: String, kind: LibraryItemPhotoKind, itemId: UUID) async throws
    func fetchLibraryItemPhotoData(kind: LibraryItemPhotoKind, itemId: UUID) async throws -> Data
    func deleteLibraryItemPhoto(kind: LibraryItemPhotoKind, itemId: UUID) async throws
}

extension LibraryRepository {
    // 기본 구현: 사진을 지원하지 않는 저장소(로컬 모드, 테스트 목)용.
    func uploadLibraryItemPhoto(_ imageData: Data, fileName: String, kind: LibraryItemPhotoKind, itemId: UUID) async throws {
        throw APIError.unsupportedOperation("사진은 서버에 연결된 상태에서만 저장할 수 있어요.")
    }

    func fetchLibraryItemPhotoData(kind: LibraryItemPhotoKind, itemId: UUID) async throws -> Data {
        throw APIError.unsupportedOperation("사진은 서버에 연결된 상태에서만 볼 수 있어요.")
    }

    func deleteLibraryItemPhoto(kind: LibraryItemPhotoKind, itemId: UUID) async throws {
        throw APIError.unsupportedOperation("사진은 서버에 연결된 상태에서만 삭제할 수 있어요.")
    }

    /// 연결 수를 셀 수 없는 구현(로컬 샘플 등)은 0을 돌려 고지를 생략한다.
    /// 0을 "연결 없음"으로 단정하지 않는다. 화면은 0일 때 고지 문장을 붙이지 않을 뿐이다.
    func linkedProjectCount(forYarnId yarnId: UUID) async throws -> Int { 0 }
    func linkedProjectCount(forNeedleId needleId: UUID) async throws -> Int { 0 }
    func linkedProjectCount(forToolId toolId: UUID) async throws -> Int { 0 }
}
