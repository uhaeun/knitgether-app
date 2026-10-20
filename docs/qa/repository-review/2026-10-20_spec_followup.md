# 뜨개더 SPEC v2.5 후속 점검 — 2026-10-20

> **문서·코드 정적 대조 결과**입니다. 앱·서버를 새로 기동해 실행한 결과가 아닙니다. 2026-09-15 QA 기준선 v2.5의 48개 ID를 유지하고, 현재 main 코드(2026-10-20 조회)와 과거 검증 기록의 차이를 구분합니다. 원문을 역사적으로 덮어쓰지 않고 후속 판단 후보를 기록합니다.

## 1. 결론

- `02_functional_spec.md`의 고유 SPEC ID 48개: **중복 0, 그룹별 번호 누락 0**.
- 과거 40↔42개 차이: 2026-08-27 `e4de8cb` 문서의 목록 40개에 `PAT-06`(일치), `PAT-07`(미대조) 두 행이 빠졌고, 8/30 보완 뒤 `f93aacc`에서 42개로 확인됨. 기존 40개 행의 판정 문자열 변화는 없었음.
- `12_quality_metrics.md`에서 42개라고 소개하며 40개 합산 표를 인용한 부분은 **40개 행 기준의 과거 요약 통계**임을 표시할 것. 최신 48개 평가 분포라고 사용 금지.
- `UI-03`: 9/1 사용자 단위 선택 기준은 이후 픽커 제거 및 cm 고정 정책으로 대체됨. **역사적 기록은 유지하고 최신 정책의 승인·명세 개정 필요**.
- `SYNC-11`: 9/1 서버본 표시 및 수정본 폐기 서술은 9/6~9/15 충돌 처리 개선 후 불완전. 현 코드는 409 때 서버본을 재조회하면서 **편집 중 메모와 카운터 화면값을 보존**하고 실패·재저장을 안내함. 모든 입력 필드 보존까지 검증됐다는 뜻은 아님.
- 1차 RTM(09의 2절)에 직접 연결된 SPEC은 **28/48개**이고, 나머지 20개는 후속 문서와 테스트로 재연결해야 함. **20개 미테스트라는 뜻이 아님.**

## 2. 과거 정적 코드 일치 판정 40→42

2026-08-30 보완 후 42개 행을 상호 배타적인 **단일 판정 / 혼합 판정**으로 다시 분류한 결과:

| 구분 | 건수 | 비고 |
| --- | ---: | --- |
| 일치 단독 | 16 | `PAT-06` 포함 |
| 조건부 일치 단독 | 2 | `SYNC-11`, `LINK-04` |
| 불일치 의심 단독 | 10 | |
| 불일치 확정 단독 | 5 | |
| 미대조 단독 | 5 | `PAT-07` 포함 |
| **혼합 상태** | **4** | `LINK-07`, `PAT-01`, `PAT-04`, `PAT-05`: 전단/후단 또는 경로에 따라 판정 다름 |
| **합계** | **42** | 8/30 기록의 판정 문자열 분류. 최신 실행 판정 아님 |

기존 표의 '일치와 그 외 19'는 단독 판정과 일부 혼합 상태를 분리하지 않아 정의가 모호하다. 기존 시점의 40건 통계는 그대로 보존하고, 재작성 시 위 6구분을 사용한다. v2.5 48건의 동일한 분포를 뜻하지 않는다.

## 3. UI-03 최신 정책 차이

- 2026-09-01 SPEC: 온보딩·회원가입·프로필에서 Metric / Imperial 선택을 일치시키되, 게이지 계산에는 적용하지 않음.
- 2026-09-06 변경: `52dee72`에서 사용자가 선택하는 단위 UI를 제거. 현재 `OnboardingView.swift`, `ProfileSettingsView.swift`에서 단위 선택 없음. `SettingsView.swift`에도 제거 기록이 있음. 게이지 계산은 cm 기준.
- `OnboardingFormData`·`ProfileFormData`의 `preferredUnits` 필드는 **데이터 모델에 여전히 존재**: 모델 필드 제거와 UI 제거는 다름.
- 결함 `DEF-26`, `DEF-29`는 픽커 제거와 설정 문구 보완으로 처리, `UI-01` 및 `OnboardingViewModelTests` 등에서 일부 회귀 근거 기록.
- **최신 정책 반영 제안:** "MVP에서 사용자는 단위계를 선택하지 않는다. 게이지 계산과 길이 입력의 표시 단위는 cm이다. 기존 프로필의 `preferredUnits` 저장 필드는 호환성 목적으로 남을 수 있으나 입력·계산 단위 변경 기능으로 사용하지 않는다." *최신 스펙 개정은 제품 오너 승인 후 적용.*

## 4. SYNC-11 최신 충돌 처리와 검증 범위

- 서버 동시 수정 감지: `PATCH` 요청의 `baseUpdatedAt`으로 버전을 비교해 오래된 수정은 409 `PROJECT_CONFLICT` 반환.
- 클라이언트: `RemoteProjectRepository.swift`가 마지막 서버 갱신 시각을 저장(앱 재시작 이후에도 유지). 서버에 이미 존재하는 ID의 POST는 409 `PROJECT_ALREADY_EXISTS` 경로로 취급하고 최신 기준으로 PATCH를 시도.
- 화면: `ProjectWorkspaceViewModel.swift`의 `handleProjectSaveFailure`가 충돌 시 서버 최신본을 재조회하고 `applyProjectState(..., preservingUserEdits: true)` 호출. 이 메서드에서 명시적으로 보존하는 폼 값은 **`memoText`와 `currentRow`**. 전체 프로젝트 객체는 서버본으로 갱신됨.
- 안내: "다른 기기에서 먼저 수정돼서 저장하지 못했어요. 입력하신 내용은 그대로 있어요. 다시 저장하면 이 기기의 내용으로 저장돼요."
- 시험 근거: `ProjectWorkspaceViewModelTests.swift`의 `projectSaveConflictKeepsUnsavedMemoInsteadOfServerValue`, `projectSaveConflictRefetchesServerProjectToRefreshLockBaseline`, `projectSaveConflictMessageSaysInputIsKept`; 서버 기준은 `test_17_conflict_timestamp_precision.py`의 최신 타임스탬프 / stale 타임스탬프 확인.
- **후속 결정 제안:** "저장 충돌 시 서버의 선행 수정은 유지하고 해당 저장 요청은 거부한다. 화면은 서버 최신본을 가져오되 보존이 검증된 편집값은 유지하며, 사용자가 재저장할 수 있도록 안내한다. 필드별 편집값 보존과 병합 정책은 별도 검증·정의한다." 이 문장을 곧바로 모든 미저장 데이터의 무손실 보장으로 표현하지 않는다.
- 실기기 또는 시뮬레이터 두 세션의 **끝에서 끝까지 충돌→메모 보존→재저장** E2E 실측은 이번 정적 리뷰로 확인하지 않았음.

## 5. SPEC 48개 추적성 1차 대조

의미: '1차 RTM'은 `09_test_case_master.md`의 1차 SPEC→TC 표에 명시된 연결이고, '후속 확인 필요'는 해당 표 바깥에 기록된 별도 테스트/결함 증거 후보를 뜻한다. 직접 증거 연결이 없더라도 기능을 테스트하지 않았다고 판정하지 않는다.

| SPEC | 1차 RTM 상태 | 후속 연결·미확인 범위 |
| --- | --- | --- |
| SYNC-01 | 1차 RTM: TC-SYNC01-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-02 | 1차 RTM: TC-SYNC01-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-03 | 후속 확인 필요 | 07 수동 API/Charles. 1차 RTM은 07 이관으로 표기 |
| SYNC-04 | 1차 RTM: TC-SYNC01-01, TC-CUJ2-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-05 | 1차 RTM: TC-SYNC05-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-06 | 1차 RTM: TC-SYNC06-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-07 | 1차 RTM: TC-SYNC01-01, TC-SYNC06-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-08 | 1차 RTM: TC-SYNC08-01, TC-SYNC08-02 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-09 | 1차 RTM: TC-SYNC09-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-10 | 1차 RTM: TC-SYNC10-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| SYNC-11 | 1차 RTM: TC-SYNC08-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-01 | 1차 RTM: TC-LINK01-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-02 | 1차 RTM: TC-CUJ1-01, TC-CUJ3-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-03 | 1차 RTM: TC-LINK03-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-04 | 1차 RTM: TC-CUJ3-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-05 | 1차 RTM: TC-LINK05-01, TC-CUJ3-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| LINK-06 | 후속 확인 필요 | 05 후속 수동 트랙 D; 기능별 TC-ID/실행 증거 재연결 필요 |
| LINK-07 | 후속 확인 필요 | 05 TC-LINK07-02 (오프라인 연결은 과거 불일치); 현재 동작·PASS 재점검 |
| LINK-08 | 후속 확인 필요 | 05 후속 수동 트랙 D; 개별 케이스·실행 증거 미연결 |
| LINK-09 | 후속 확인 필요 | 05 후속 수동 트랙 D; 개별 케이스·실행 증거 미연결 |
| LINK-10 | 후속 확인 필요 | 10 DEF-25; library.e2e + LibraryItemViewModelTests. 오프라인 고지는 별도 제한 |
| CNT-01 | 1차 RTM: TC-CNT01-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| CNT-02 | 1차 RTM: TC-CNT02-01, TC-CUJ2-01, TC-CUJ4-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| CNT-03 | 1차 RTM: TC-CNT03-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-01 | 1차 RTM: TC-CUJ1-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-02 | 1차 RTM: TC-CUJ2-01, TC-PAT02-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-03 | 1차 RTM: TC-LINK01-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-04 | 1차 RTM: TC-CUJ3-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-05 | 1차 RTM: TC-CUJ4-01, TC-PAT05-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| PAT-06 | 후속 확인 필요 | 05 과거 TC-PAT06-01, 02의 8/30 API 재현. 09 RTM에는 연결 미반영 |
| PAT-07 | 후속 확인 필요 | 05 과거 TC-PAT07-01. 오프라인 진행 사진 실측 경로 확인 필요 |
| PAT-08 | 후속 확인 필요 | UI-49 (DEF-18 보기 모드 드로잉 회귀) |
| AUTH-01 | 후속 확인 필요 | 07 토큰 만료 검증 + 저장 위치는 클라이언트 별도 확인 |
| AUTH-02 | 1차 RTM: TC-AUTH02-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| AUTH-03 | 1차 RTM: TC-AUTH04-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| AUTH-04 | 1차 RTM: TC-AUTH04-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| AUTH-05 | 1차 RTM: TC-AUTH05-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| AUTH-06 | 1차 RTM: TC-AUTH04-01, TC-AUTH05-01 | 1차 기준과 현재 버전의 기대 동작이 같은지 확인 |
| AUTH-07 | 후속 확인 필요 | 05 과거 TC-AUTH07-01, Appium UI-77 후속 게이트 검증 |
| AUTH-08 | 후속 확인 필요 | 09 API-29 4건, 서버 e2e 4건 (2026-09-15) |
| TIME-01 | 후속 확인 필요 | 05 후속 수동 트랙 D; TIME-02/DEF-23 회귀와 분리해 기대값 확인 |
| TIME-02 | 후속 확인 필요 | qa/appium/tests/test_def23_background_session.py (장/단시간 2경로, 단시간 검출력 미확인) |
| TIME-03 | 후속 확인 필요 | 09 API-12 PARTIAL: 24시간 상한·500자 단언 부족, 클라이언트 4시간 절단도 별도 검증 |
| UI-01 | 후속 확인 필요 | 05 후속 수동 트랙 D, 해당 입력 폼 경계 테스트와 직접 연결 필요 |
| UI-02 | 후속 확인 필요 | 05 후속 수동 트랙 E; 자동 회귀 케이스·실행 증거 직접 연결 필요 |
| UI-03 | 후속 확인 필요 | DEF-26·29; UI-01·OnboardingViewModelTests는 픽커 제거 확인. 9/1 SPEC은 최신 UI와 불일치 |
| PROJ-01 | 후속 확인 필요 | UI-17 (1/30/31자); 서버 경계는 API-27 등과 매핑 필요 |
| PROJ-02 | 후속 확인 필요 | API-27 서버 경계 일부, UI-17은 프로젝트 이름 한정; 4종 입력 전체 확인 필요 |

## 6. 우선 후속 조치

1. **P0 — 명세 기준 업데이트:** UI-03을 과거 v2.5와 현재 사용 단위 cm 기준으로 구분하고 SYNC-11 충돌 후 폼 값 보존 범위를 명시. 기존 9월 원문은 삭제하지 않음.
2. **P0 — RTM 강화:** 위 20개 SPEC에 대한 2차 TC-ID/테스트 코드/실행 근거를 연결해 미연결과 미실행을 구분. 특히 `TIME-03`, `LINK-07`, `PAT-07`은 부분·미확인 범위를 숨기지 않음.
3. **P1 — 저장 충돌 실측:** 두 기기 편집 → 선행 저장 → 뒤따른 409 → 메모 등 잔존값 → 서버 최신값 → 재저장 → DB 최종값 검증. 드로잉·도안·연결값은 메모와 별개로 판정.
4. **P1 — 사용자 단위 정책 회귀:** 단위 선택 화면 부재, cm 표기 일관성, 과거 preferredUnits 데이터가 화면과 계산에 영향을 주지 않는지 확인.
5. **P1 — 통계 명칭 보강:** '40행 분류표(과거)'와 '42개 SPEC 목록(보완 후)', '48개 기준선(v2.5)'을 지표 표에 동시에 명시.

## 7. 근거

- [02 SPEC 기준선](../portfolio/02_functional_spec.md), [09 RTM](../portfolio/09_test_case_master.md), [05 테스트 케이스](../portfolio/05_test_cases.md), [12 품질 지표](../portfolio/12_quality_metrics.md)
- [15 릴리즈 판정](../portfolio/15_release_decision.md), [10 결함 대장](../portfolio/10_defect_catalog.md)
- [RemoteProjectRepository.swift](../../../KnitGether/Repositories/Remote/RemoteProjectRepository.swift), [ProjectWorkspaceViewModel.swift](../../../KnitGether/ViewModels/ProjectWorkspaceViewModel.swift), [충돌 처리 단위 테스트](../../../KnitGetherTests/ProjectWorkspaceViewModelTests.swift)
- [OnboardingView.swift](../../../KnitGether/Views/Onboarding/OnboardingView.swift), [ProfileSettingsView.swift](../../../KnitGether/Views/Tool/ProfileSettingsView.swift), [GaugeCalculatorViewModel.swift](../../../KnitGether/ViewModels/GaugeCalculatorViewModel.swift)
- [GitHub 40개 목록 커밋](https://github.com/uhaeun/knitgether-app/blob/e4de8cb/docs/qa/portfolio/02_functional_spec.md), [42개 목록 커밋](https://github.com/uhaeun/knitgether-app/blob/f93aacc/docs/qa/portfolio/02_functional_spec.md)
