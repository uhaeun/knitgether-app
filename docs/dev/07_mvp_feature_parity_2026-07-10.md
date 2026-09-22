# KnitGether MVP 기능/화면 1:1 대조

작성일: 2026-07-10

## 비교 대상

- MVP 원본: `~/Desktop/Projects/knitgether-mvp/KnitGether`
- 현재 개발 브랜치: `~/Desktop/Projects/KnitGether/.worktrees/ios-sync-api-project-list`

## 결론

현재 브랜치는 `knitgether-mvp`의 큰 기능 줄기를 상당수 서버-클라이언트 구조로 복원했다. 2026-07-11 UI/UX parity 작업으로 Settings 5번째 탭, 공통 카드 테마, Tool/Library 카드형 홈, Workspace 카드 섹션, Library 세부 목록/상세, Workspace 핵심 세부 패널, Gauge 상세 측정, Skill Test/Dictionary/Animation 목록 스타일을 복원했다. 다만 MVP와 모든 세부 컴포넌트가 1:1 동일한 상태는 아직 아니다.

현재 구조는 CoreData 화면/뷰모델을 그대로 옮긴 것이 아니라, 서버 Repository와 OfflineFirst cache에 맞춰 화면을 통합/재구성했다. 따라서 “기능 존재”와 “MVP와 동일한 UX”를 분리해서 봐야 한다.

## 정량 비교

- MVP SwiftUI View 파일: 117개
- 현재 SwiftUI View 파일: 61개
- 동일 basename View 파일: 26개
- MVP ViewModel 파일: 22개
- 현재 ViewModel 파일: 19개
- 동일 basename ViewModel 파일: 4개

파일 수가 줄어든 이유는 일부 기능이 통합 화면으로 합쳐졌기 때문이다. 다만 아래 항목처럼 아직 명확히 빠진 화면/UX도 있다.

## 탭 구조

| 영역 | MVP | 현재 브랜치 | 판정 |
| --- | --- | --- | --- |
| Home | `HomeView` | `HomeView` | 복원됨 |
| My Knitting | `MyKnittingView` | `MyKnittingView` | 복원됨 |
| Tool | `ToolView` | `ToolView` | 카드형 도구 홈으로 복원됨 |
| Library | `LibraryView` | `LibraryView` | 복원됨 |
| Settings | `SettingsView` 별도 탭 | `SettingsView` 별도 탭 | 복원됨 |

## Library

| MVP 기능 | MVP 파일 | 현재 대응 | 판정 |
| --- | --- | --- | --- |
| 도안 창고 | `PatternStorageView`, `PatternDetailView` | `PatternLibraryView` | 기능 복원, 카드형 목록/상세 보강 |
| 실 창고 | `YarnStorageView`, `YarnCardView`, `YarnDetailView`, `YarnFormView` | `YarnLibraryView`, `YarnLibraryViewModel` | 기능 복원, 카드형 목록/상세 보강 |
| 바늘 창고 | `NeedleStorageView`, `NeedleCardView`, `NeedleDetailView`, `NeedleFormView` | `NeedleLibraryView`, `NeedleLibraryViewModel` | 기능 복원, 카드형 목록/상세 보강 |
| 도구 창고 | `ToolStorageView`, `ToolItemDetailView`, `ToolItemFormView` | `ToolLibraryView`, `ToolLibraryViewModel`, 서버 API | 기능 복원, 카드형 목록/상세 보강 |
| 스킬 창고 | `SkillStorageView`, `SkillDetailView`, `SkillLevelPickerView`, `SkillSummaryView` | `SkillLibraryView`, `SkillDetailView`, `SkillLevelBadgeView` | 기능 복원, 카드형 목록 보강 |

## Workspace / Project

| MVP 기능 | MVP 파일 | 현재 대응 | 판정 |
| --- | --- | --- | --- |
| 작업공간 본체 | `WorkspaceView` | `ProjectWorkspaceView` | 복원됨, 구조/UX 다름 |
| 작업공간 헤더/요약 | `WorkspaceHeaderView`, `WorkspaceSummaryView` | `ProjectWorkspaceHeaderView`, `ProjectWorkspaceSummaryView` | 복원됨 |
| 도안 보기 모드 | `PatternPlaceholderView`, `PatternPreviewView` | `ProjectPatternPanelView`, `PDFKitView` | 복원됨, 상태/모드/그리기 패널 보강 |
| 도안 등록 | `PatternRegistrationSheet` | 프로젝트 workspace의 도안 창고/직접 PDF/수동 도안 연결 | 기능 복원 |
| 도안 위 그리기 | `PatternDrawingContainerView`, `PatternDrawingToolbarView` | `PencilCanvasView`, project pattern drawing 저장 | 기능 복원, 툴바 UX 차이 있음 |
| 단수 카운터 | `SimpleCounterView`, `CounterControlButtonsView`, `CounterEditSheet` | `ProjectCounterPanelView`, `NumberEditSheet`, `CounterMemoEditSheet` | 기능 복원, 현재 단/진행률/메모 패널 보강 |
| 카운터 모드/메모/목표 단수 | `CounterModePickerView`, `CounterMemoSectionView` | `ProjectCounterPanelView`, `ProjectWorkspaceViewModel` | 복원됨 |
| 현재 행안내 | `CurrentRowInstructionView` | `ProjectRowGuidePanelView` | 복원됨, 현재 스킬/현재 행안내 패널 보강 |
| 행안내 목록/폼 | `RowInstructionListView`, `RowInstructionFormView`, `RowInstructionCardView` | `ProjectRowGuidePanelView`, 내부 sheet | 기능 복원, 카드형 행안내 row 보강 |
| 행안내 대량 붙여넣기 | `BulkRowInstructionPasteView` | `RowInstructionSheet.bulk` | 기능 복원, partial API는 아직 fallback |
| 스킬 태그/범례 | `SkillTagView`, `SkillLegendView`, `SkillQuickDetailSheet` | `SkillTagChipView`, related skills section | 부분 복원, 상세 sheet/범례는 약함 |
| 작업 시간 | `WorkSessionCardView`, `WorkSessionListView` | `ProjectWorkTimePanelView`, `ProjectWorkSessionListView` | 복원됨, 통계/세션 카드 보강 |
| 작업 세션 메모 | `SessionNotesSheet` | `WorkSessionMemoEditSheet` | 복원됨 |
| 진행 사진 | `ProgressPhotoThreadView`, `ProgressPhotoCardView` | `ProjectProgressPhotoPanelView` | 기능 복원, 썸네일 카드 보강 |
| 실 사용 기록 | `WorkspaceYarnSectionView` | `ProjectYarnUsagePanelView` | 복원됨, 요약/기록 패널 보강 |
| 바늘 연결 | `WorkspaceNeedleSectionView` | `ProjectNeedlePanelView` | 복원됨, 연결 row/picker 보강 |
| 도구 연결 | `WorkspaceToolSectionView`, `ToolPickerSheetView` | `ProjectToolPanelView` | 복원됨, 연결 row/picker 보강 |
| 게이지 기록 연결 | `WorkspaceGaugeSectionView`, `GaugeRecordPickerSheetView` | `ProjectGaugeRecordPanelView` | 복원됨, 세탁 전후 비교/연결 row 보강 |

## Gauge

| MVP 기능 | MVP 파일 | 현재 대응 | 판정 |
| --- | --- | --- | --- |
| 게이지 계산기 | `GaugeCalculatorView`, `GaugeInputSectionView`, `GaugeResultView` | `GaugeCalculatorView`, `GaugeCalculatorViewModel` | 기능 복원, UI 통합 |
| 기록 목록/상세/카드 | `GaugeRecordListView`, `GaugeRecordDetailView`, `GaugeRecordCardView` | `GaugeCalculatorView` 내부 기록 UX | 기능 복원, 별도 화면 구조는 다름 |
| 세탁 전/후 비교 | `GaugeRecord` 흐름 | `GaugeWashComparison`, workspace/gauge view | 복원됨 |
| 측정 허브 | `GaugeMeasureHubView` | `GaugeMeasureHubView` | 복원됨, 카드형 최근 목표 목록 보강 |
| 목표 게이지 목록/상세/폼 | `GaugeTargetListView`, `GaugeTargetDetailView`, `GaugeTargetFormView` | `GaugeMeasureHubView`, `GaugeTargetDetailView`, `GaugeTargetFormView` | 대부분 복원, 상세 패널 보강 |
| 스와치 목록/상세/폼 | `SwatchListView`, `SwatchDetailView`, `SwatchFormView` | `GaugeSwatchListView`, `SwatchDetailView`, `GaugeSwatchFormView` | 복원됨, 카드형 목록/상세 보강 |
| 측정 방법 선택 | `MeasurementMethodPickerView` | `MeasurementMethodPickerView` | 복원됨, 카드형 방식 선택 보강 |
| 수동 측정 | `ManualMeasurementView` | `ManualMeasurementView` | 복원됨 |
| 사진 4점 측정 | `Photo4ptMeasurementView` | `Photo4ptMeasurementView` | 기본 복원, 카메라 캡처/오버레이 세부 UX 일부 축소 |
| 측정 결과/수정/행 | `MeasurementResultView`, `MeasurementEditView`, `MeasurementRowView` | 같은 타입이 `GaugeMeasurementViews.swift` 안에 통합 | 복원됨 |
| 빠른 측정 플로우 | `QuickMeasureFlowView` | `GaugeQuickMeasureFlowView` | 복원됨 |

## Tool / Skill / Dictionary / Animation

| MVP 기능 | MVP 파일 | 현재 대응 | 판정 |
| --- | --- | --- | --- |
| 스킬 테스트 | `SkillTestView` 계열 | `Views/Tool/SkillTest/*` | 복원됨, 카드형 진행/결과 보강 |
| 스킬 이해도 신호등 | `SkillLevelPickerView`, skill level 표시 | `SkillLevelFormatter`, `SkillLevelBadgeView`, 스킬 테스트 | 복원됨, 최근 `헷갈려요`로 정리 |
| 뜨개 사전 | `KnitDictionaryView`, term detail/card/related skill | `KnitDictionaryView` | 기능 복원, 카드형 목록/상세 보강 |
| 뜨개 애니메이션 | `KnitAnimationView`, `KnitStepAnimationView`, `SkillLearningStepsView` | `KnitAnimationView`, `SkillAnimationDetailView` | 기능 복원, 단계별 학습/목록 카드 보강, MVP 일러스트 일부 축소 |
| Tool 메인 카드 UX | `ToolNavigationCard` | `AppNavigationCard` 기반 카드 홈 | 복원됨 |

## Settings

| MVP 기능 | MVP 파일 | 현재 대응 | 판정 |
| --- | --- | --- | --- |
| Settings 별도 탭 | `SettingsView` | `SettingsView` | 복원됨 |
| 프로필 요약 카드 | `ProfileSummaryView` | `SettingsView` 프로필 카드 | 복원됨 |
| 프로필 편집 | `ProfileEditView` | `ProfileSettingsView` | 기능 복원, UI 다름 |
| 계정 연동 | `AccountLinkingView` | `AuthAccountView` | 기능은 확장 복원됨 |
| 데이터 백업 | `DataBackupView` | `DataBackupView` | 복원됨, export/import까지 확장, 테마 적용 |
| 데이터 관리 | `DataManagementView` | `DataManagementView` | 복원됨, 테마 적용 |
| 작업시간 통계 | `WorkTimeStatisticsView` | `WorkTimeStatisticsView` | 복원됨, 요약/세션 카드 보강 |
| 작업 세션 목록 | `WorkSessionListView` | `ProjectWorkSessionListView` | 프로젝트 내부로 복원, 세션 카드 보강, Settings 전역 목록은 없음 |
| 상태 설명 | `ProjectStatusGuideView` | `ProjectStatusGuideView` | 복원됨 |
| 앱 정보 | `AppInfoView` | `AppInfoView` | 복원됨 |

## 명확히 미복원 또는 약한 부분

1. MVP 디자인 시스템 세부 확장
   - `AppTheme`, `AppCardStyle`, `SectionHeaderView`, `EmptyStateView`, `AppDetailHeaderView`, `AppDetailInfoRow`, `AppSoftPanel`은 현재 구조에 재도입했다.
   - 주요 세부 화면에는 적용했지만, 모든 Form row와 MVP 전용 일러스트까지 1:1 복원한 것은 아니다.

2. Workspace의 세부 컴포넌트 1:1 화면
   - 기능은 많이 복원됐지만 MVP의 `Workspace*`, `Counter*`, `RowInstruction*`, `Pattern*` 컴포넌트들이 대부분 현재 패널/시트 내부 구현으로 바뀌었다.
   - 2026-07-11 작업으로 섹션 카드와 주요 세부 패널 스타일은 복원했지만, 개별 컴포넌트 이름/구조까지 1:1은 아니다.

3. Dictionary/Animation 상세 UX
   - 사전 카드/상세/관련 스킬, 애니메이션 단계별 학습은 보강했다.
   - 프로젝트 도안 작업 중에도 사전/스킬 빠른 조회 sheet로 이어진다.
   - MVP의 전용 일러스트/모션 리소스 수준까지는 아직 아니다.

4. Gauge 사진 4점 측정 세부 UX
   - 사진 선택과 4점 측정 기본 플로우는 있다.
   - MVP의 카메라 캡처, overlay/marker 세부 타입 일부는 현재 통합/축소되어 있다.

5. 전역 작업 세션 목록
   - Settings에 전역 `WorkSessionListView`를 복원했다.
   - 전체 프로젝트 세션을 모아 보고, 세션 메모 수정과 삭제를 할 수 있다.

6. QA 자동화 준비
   - 탭, 프로젝트 CRUD, Library CRUD, Workspace 반복 입력, Gauge 측정, Settings/Auth/Onboarding에 accessibility identifier를 추가했다.
   - Appium에서는 `AppAccessibilityID`의 문자열을 기준으로 주요 CRUD/연결 시나리오를 안정적으로 잡을 수 있다.

## 현재 구현이 MVP보다 확장된 부분

- 서버 API + PostgreSQL/Prisma 구조
- OfflineFirst Repository/cache
- 회원가입/로그인/계정별 캐시 전환
- 백업 JSON export/import
- 400/404 롤백 정책
- 프로젝트 하위 데이터 partial API 일부
- 도안/도구/실/게이지 기록 서버 동기화
- 도안 작업 중 사전/스킬 빠른 조회
- Appium QA용 접근성 식별자 계층

## 다음 권장 작업

1. Dictionary/Animation 상세 UX를 MVP 수준으로 더 다듬는다.
   - 관련 스킬 카드, 단계별 학습, 애니메이션 placeholder/illustration 계층 복원

2. 남은 Form/Picker 계층을 실제 기기에서 QA한다.
   - 목록/상세는 카드형으로 보강했지만, 일부 입력 Form은 iOS 기본 Form을 유지한다.

3. 수동 QA에서 실제 1:1 플로우를 확인한다.
   - MVP와 현재 앱을 나란히 띄워 탭별 화면 진입, 버튼, 빈 상태, 저장/수정/삭제를 비교한다.
