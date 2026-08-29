# 09_테스트 케이스 마스터

> 2차 사이클 케이스 카탈로그. 원본은 구글시트 [뜨개더 TC 설계](https://docs.google.com/spreadsheets/d/1EjP0M0_BcFdMvJmjDk8-u-56_toANB4j084Hs7Bh4mI/) (최종 갱신 2026-08-24).
> 이 문서는 카탈로그다. 케이스별 스텝, Given/When/Then 전문은 시트가 정본이다.
> 1차 사이클(TC-CUJ, TC-SYNC 계열 21건)은 05와 06이 정본이며, 여기에는 계보만 싣는다.

**미기입 열 안내**: `자동/수동`과 `판정 근거` 두 열은 비어 있다. 이 판단이 이 문서의 핵심이라 QA(유하은)가 직접 채운다. 나머지 열은 시트와 리포지토리에서 옮기거나 실측한 사실이다.

---

## 1. TC 그룹 (TC1~TC16)

시트 `로드맵` 탭. 층, 기법, 우선순위, 근거, 제약은 시트 원문이다.

| TC | 항목 | 층 | 기법 | 우선순위 | 제약 | UI 케이스 | API 케이스 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC1 | 온보딩 (6페이지) | 스모크 | 시나리오 | P1 | 초기 상태 필요(앱 초기화 옵션). 6페이지 완주 기준 | UI-01 | 없음 |
| TC2 | 회원가입 | 스모크 | 경계값, 에러 기대, 시나리오 | P1 | 서버 필요, 매 실행 고유 이메일 | UI-02~07 | API-01~03 |
| TC3 | 로그인 | 스모크 | 시나리오, 에러 기대 | P1 | 서버 필요, 테스트 계정 필요 | UI-08~12 | API-04, 05 |
| TC4 | 프로젝트 추가 | 스모크 | 시나리오 | P1 | 로컬 가능 | UI-13~17 | API-06~09, 15, 21 |
| TC5 | 프로젝트 수정 | 기능 | 시나리오 | P2 | 로컬 가능 | UI-18~27 | API-10 |
| TC6 | 프로젝트 삭제 | 기능 | 상태 전이 | P2 | 로컬 가능 | UI-28~31 | API-11 |
| TC7 | 프로젝트 개수 한계 | 기능 | 경계값 | P3 | 로컬 가능 | UI-32 | 없음 |
| TC8 | 프로젝트 정렬과 필터 | 기능 | 시나리오, 상태 전이 | P3 | 로컬 가능 | UI-33~36 | API-25 |
| TC9 | 프로젝트 즐겨찾기 | 기능 | 상태 전이 | P3 | 로컬 가능 | UI-37~38 | 없음 |
| TC10 | 프로젝트 작업 화면 (도안, 카운터, 정보 탭) | 여정 | 시나리오, 상태 전이, 경계값, 회귀 | P1 | 로컬 가능 (일부 시스템 UI 수동) | UI-39~63 | API-12, 13, 16, 22~24 |
| TC11 | 재방문 보존(앱 종료 후 상태) | 여정 | 상태 전이 | P1 | 로컬 가능, 앱 재실행 명령 | UI-64 | 없음 |
| TC12 | 실 바늘 도구 등록 | 기능 | 시나리오 | P2 | 로컬 가능 | UI-65~69 | API-17 |
| TC13 | 등록 항목 수정 | 기능 | 시나리오 | P3 | 로컬 가능 | UI-70~72 | API-17 (사이클 포함) |
| TC14 | 등록 항목 삭제 | 기능 | 상태 전이 | P2 | 로컬 가능 | UI-73~76 | API-17 (사이클 포함) |
| TC15 | 로그아웃 | 기능 | 상태 전이 | P2 | 서버 필요 | UI-77 | API-14 |
| TC16 | 오프라인 생성 후 복구 동기화 | 여정 | 상태 전이 | P2 | 서버와 네트워크 제어, 수동 유지 | UI-78 | API-18~20 |

**TC 선정 근거 (시트 원문)**

| TC | 왜 이 우선순위인가 |
| --- | --- |
| TC1 | 모든 신규 사용자가 반드시 지나는 첫 관문. 기존 자동화는 온보딩을 건너뛰도록 설계돼 있어(launch argument 우회) 테스트 사각지대가 된 지점 |
| TC2 | 진입 관문, 판정 명확. 서버 규칙(비밀번호 8~256자) 코드로 확인 |
| TC3 | 진입 관문. 기존 계정 재사용으로 자동화 단순 |
| TC4 | 모든 여정의 시작점 |
| TC5 | CRUD 기본, 판정 명확 |
| TC6 | 삭제 후 잔존 여부까지. 캐시 잔존 결함(DEF-11) 이력 계열 |
| TC7 | 상한 명세 없음(명세 공백), 탐색적 |
| TC8 | 순서 비교라 판정 명확. DEF-17 회귀 3건 포함 |
| TC9 | 토글 상태의 보존 확인 |
| TC10 | 도안, 카운터, 정보 탭 통합 영역. 카운터 하한은 DEF-15 회귀 이력으로 P1 |
| TC11 | CUJ-2 계열, 작업 재개는 핵심 가치 |
| TC12 | 창고 기본 CRUD |
| TC13 | CRUD 기본. 스냅샷 비전파(LINK-05) 연계 |
| TC14 | 스냅샷 보존(LINK-05) 연계 |
| TC15 | AUTH-06 게이트 동작. 계정 격리(치명도 3위) 계열 |
| TC16 | 치명도 1위 계열이나 자동화 비용 큼 |

**범위 결정 (시트 원문)**: 신규 구현은 Appium 표준. XCUITest 기존 2건과 CI 게이트는 유지. 전체 삭제 기능은 코드 확인 결과 미구현으로 대상 제외. 실 바늘 도구의 프로젝트 연결과 해제는 UI-68~69가 담당.

---

## 2. UI 케이스 (UI-01 ~ UI-78)

`Appium 함수` 열은 2026-08-27 리포지토리 실측이다. 함수가 존재한다는 사실이지 통과했다는 판정이 아니다.
`시트 상태` 열은 2026-08-24 시트 원문이며 갱신하지 않는다. 그 시점의 수동 판정을 남겨두어야 자동 재실행과 구분되기 때문이다.
`자동 실행 판정` 열은 2026-08-29 분할 실행 3회(정방향 2회, 역순 1회) 결과다. 세 회차가 모두 79 passed, 1 skipped, 0 failed로 같았으므로 실행된 케이스는 전건 PASS다.

**이 열을 읽을 때 주의할 것.** 시트에 `PASS (8/23)` 로 적힌 11건은 이미 수동으로 통과한 케이스다. 여기서 다시 PASS가 나온 것은 신규 발견이 아니라 자동 재실행이다. 반대로 `실행 대기` 56건은 이번 자동 실행이 첫 판정이다.

| 케이스 | TC | 시나리오 | 기법 | Appium 함수 (8/27 실측) | 시트 상태 (8/24) | 자동 실행 판정 (8/29) | 자동/수동 | 판정 근거 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UI-01 | TC1 | 온보딩 6페이지 완주 후 메인 페이지 확인 | 시나리오 | `test_ui_01_complete_six_pages` | 실행 대기 | PASS |  |  |
| UI-02 | TC2 | 회원가입 성공 | 시나리오 | `test_ui_02_signup_success` | 실행 대기 | PASS |  |  |
| UI-03 | TC2 | 회원가입 실패 - 중복 이메일 | 에러 기대 | `test_ui_03_duplicate_email_rejected` | 실행 대기 | PASS |  |  |
| UI-04 | TC2 | 회원가입 실패 - 잘못된 이메일 형식 | 에러 기대 | `test_ui_04_05_06_submit_disabled_on_invalid_input` (3건 통합) | 실행 대기 | PASS |  |  |
| UI-05 | TC2 | 회원가입 실패 - 비밀번호 미입력 | 경계값 | 위와 동일 함수 | 실행 대기 | PASS |  |  |
| UI-06 | TC2 | 회원가입 실패 - 비밀번호 7자 | 경계값 | 위와 동일 함수 | 실행 대기 | PASS |  |  |
| UI-07 | TC2 | 회원가입 실패 - 비밀번호 257자 | 경계값 | `test_ui_07_password_too_long_rejected` | 실행 대기 | PASS |  |  |
| UI-08 | TC3 | 로그인 성공 (DEF-16 증상 감시) | 시나리오 | `test_ui_08_login_success` | 실행 대기 | PASS |  |  |
| UI-09 | TC3 | 로그인 실패 - 빈 입력 | 에러 기대 | `test_ui_09_login_disabled_on_empty_input` | 실행 대기 | PASS |  |  |
| UI-10 | TC3 | 로그인 실패 - 이메일 형식 오류 | 에러 기대 | `test_ui_10_login_disabled_on_malformed_email` | 실행 대기 | PASS |  |  |
| UI-11 | TC3 | 로그인 실패 - 존재하지 않는 이메일 | 에러 기대 | `test_ui_11_unknown_email_rejected` | 실행 대기 | PASS |  |  |
| UI-12 | TC3 | 로그인 실패 - 잘못된 비밀번호 | 에러 기대 | `test_ui_12_wrong_password_rejected` | 실행 대기 | PASS |  |  |
| UI-13 | TC4 | 프로젝트 추가 - 상단 [+] 버튼 | 시나리오, 에러 기대, 경계값 | `test_ui_13_add_via_top_plus` | 실행 대기 | PASS |  |  |
| UI-14 | TC4 | 프로젝트 추가 - 0개 상태 [+ 추가] | 시나리오 | `test_ui_14_add_from_empty_state` | 실행 대기 | PASS |  |  |
| UI-15 | TC4 | 프로젝트 추가 - 연속 5개 | 시나리오 | `test_ui_15_add_five_in_a_row` | 실행 대기 | PASS |  |  |
| UI-16 | TC4 | 중복 이름 생성 (명세 공백 관찰) | 시나리오 | `test_ui_16_duplicate_names_allowed` | 실행 대기 | PASS |  |  |
| UI-17 | TC4 | 이름 길이 상한 경계값 (SPEC-PROJ-01) | 경계값 | `test_ui_17_name_length_boundary` | FAIL 예상 (미실행) | PASS |  |  |
| UI-18 | TC5 | 수정 - 작업 화면 경로 기본 | 시나리오 | `test_ui_18_rename_from_workspace` | 실행 대기 | PASS |  |  |
| UI-19 | TC5 | 이름만 수정 시 실 연결 유지 (작업 화면) | 시나리오, 상태 전이 | `test_ui_19_rename_keeps_yarn_link_workspace_path` | 실행 대기 | PASS |  |  |
| UI-20 | TC5 | 이름만 수정 시 실 연결 유지 (롱프레스) | 시나리오, 상태 전이 | `test_ui_20_rename_keeps_yarn_link_long_press_path` | 실행 대기 | PASS |  |  |
| UI-21 | TC5 | 스와이프 수정 진입 검증 | 시나리오 | `test_ui_21_rename_from_swipe` | 실행 대기 | PASS |  |  |
| UI-22 | TC5 | 오손상 방지 (n개 중 1개만 수정) | 상태 전이 | `test_ui_22_editing_one_project_leaves_others` | 실행 대기 | PASS |  |  |
| UI-23 | TC5 | 수정 취소 분기 | 상태 전이 | `test_ui_23_cancel_discards_changes` | 실행 대기 | PASS |  |  |
| UI-24 | TC5 | 목표일 설정과 표시 | 시나리오 | `test_ui_24_target_date_shows_and_persists` | 실행 대기 | PASS |  |  |
| UI-25 | TC5 | 목표일 표시 경계값 (D-day) | 경계값 | `test_ui_25_dday_boundary` | 실행 대기 | PASS |  |  |
| UI-26 | TC5 | 상태 변경 전이 (CO→WIP→UFO→WIP→FO) | 상태 전이 | `test_ui_26_status_transitions_persist` | 실행 대기 | PASS |  |  |
| UI-27 | TC5 | 완료 처리의 홈 집계 반영 | 상태 전이 | `test_ui_27_completion_updates_home_counts` | 실행 대기 | PASS |  |  |
| UI-28 | TC6 | 삭제 - 수정 폼 경로 (취소 분기 포함) | 상태 전이 | `test_ui_28_delete_from_edit_form_with_cancel` | 실행 대기 | PASS |  |  |
| UI-29 | TC6 | 삭제 - 롱프레스 경로 | 상태 전이 | `test_ui_29_delete_via_long_press` | 실행 대기 | PASS |  |  |
| UI-30 | TC6 | 삭제 - 스와이프 경로 | 상태 전이 | `test_ui_30_delete_via_swipe` | 실행 대기 | PASS |  |  |
| UI-31 | TC6 | 연속 삭제와 격리 (3개 중 2개) | 상태 전이 | `test_ui_31_delete_two_of_three_keeps_rest` | 실행 대기 | PASS |  |  |
| UI-32 | TC7 | 대량 생성 탐색 (30개) | 경계값, 탐색 | `test_ui_32_bulk_create_thirty` | PASS (8/23) | PASS |  |  |
| UI-33 | TC8 | 정렬 - 최근 작업 순 반영 (DEF-17 회귀) | 상태 전이, 회귀 | `test_ui_33_recent_work_moves_to_top` | FAIL 예상 (미실행) | PASS |  |  |
| UI-34 | TC8 | 정렬 - 이력 없을 때 시작일 내림차순 | 시나리오 | `test_ui_34_start_date_desc_without_history` | 실행 대기 | PASS |  |  |
| UI-35 | TC8 | 정렬 - 복수 작업 이력 간 상대 순서 | 상태 전이 | `test_ui_35_relative_order_between_histories` | FAIL 예상 (미실행) | PASS |  |  |
| UI-36 | TC8 | 필터 - 상태별 표시 | 시나리오 | `test_ui_36_status_filter` | 실행 대기 | PASS |  |  |
| UI-37 | TC9 | 즐겨찾기 토글과 상단 고정 | 상태 전이 | `test_ui_37_favorite_pins_to_top` | PASS (8/23) | PASS |  |  |
| UI-38 | TC9 | 즐겨찾기 그룹 내 정렬 (DEF-17 계열) | 상태 전이, 회귀 | `test_ui_38_order_inside_favorite_group` | FAIL 예상 (미실행) | PASS |  |  |
| UI-39 | TC10 | 작업 화면 진입 여정 (DEF-15 자동화 경로) | 시나리오, 회귀 | `test_ui_39_enter_workspace_and_counter` | 자동화 완료 | PASS |  |  |
| UI-40 | TC10 | 도안 연결 - PDF 직접 (창고 보관 안함) | 시나리오 | `test_ui_40_import_pdf_link_only` | PASS (8/23) | PASS |  |  |
| UI-41 | TC10 | 도안 연결 - PDF 직접 (창고 보관) | 시나리오 | `test_ui_41_import_pdf_keep_in_library` | PASS (8/23) | PASS |  |  |
| UI-42 | TC10 | 도안 연결 - 문서 스캔 (카메라) | 시나리오 | `test_ui_42a_document_scan_on_simulator` / `test_ui_42b_document_scan_on_device` | 실기기 수동 대기 | 42a PASS, 42b 미실행 |  |  |
| UI-43 | TC10 | 도안 연결 - 도안 창고 (DEF-13 경로) | 시나리오 | `test_ui_43_link_from_library` | PASS (8/23) | PASS |  |  |
| UI-44 | TC10 | 도안 연결 - 수동 입력 | 시나리오 | `test_ui_44_manual_pattern` | PASS (8/23) | PASS |  |  |
| UI-45 | TC10 | 도안 교체 - 드로잉 삭제 경고 (DEF-10 회귀) | 상태 전이, 회귀 | `test_ui_45_replace_warns_and_clears_drawing` | PASS (8/23) | PASS |  |  |
| UI-46 | TC10 | 도안 연결 해제 | 상태 전이 | `test_ui_46_unlink_pattern` | PASS (8/23) | PASS |  |  |
| UI-47 | TC10 | 도안 그리기 - 작성 | 시나리오 | `test_ui_47_draw_on_pattern` | PASS (8/23) | PASS |  |  |
| UI-48 | TC10 | 도안 그리기 - 재실행 후 유지 | 상태 전이 | `test_ui_48_drawing_survives_relaunch` | PASS (8/23) | PASS |  |  |
| UI-49 | TC10 | 도안 뷰어 - 드로잉 표시 (DEF-18 회귀) | 상태 전이, 회귀 | `test_ui_49_drawing_visible_in_viewer_mode` | FAIL (8/23, DEF-18) | PASS |  |  |
| UI-50 | TC10 | 도안 그리기 - 삭제 (취소 분기 포함) | 상태 전이 | `test_ui_50_delete_drawing_with_cancel` | PASS (8/23) | PASS |  |  |
| UI-51 | TC10 | 도안 뷰어 - 페이지 이동과 복귀 유지 (DEF-19 회귀) | 상태 전이, 회귀 | `test_ui_51_step2_page_kept_after_tab_round_trip` / `test_ui_51_step3_page_kept_after_lookup` | 스텝 2 FAIL, 스텝 3 PASS (8/23) | PASS |  |  |
| UI-52 | TC10 | 단수 카운터 - 간편 모드 | 시나리오 | `test_ui_52_simple_mode_increment_and_decrement` | 자동화 완료 | PASS |  |  |
| UI-53 | TC10 | 단수 카운터 - 행안내 모드 | 시나리오 | `test_ui_53_row_guide_mode` | 실행 대기 | PASS |  |  |
| UI-54 | TC10 | 단수 카운터 - 하한 경계 (DEF-15 회귀) | 경계값, 회귀 | `test_ui_54_lower_bound_stays_at_start` | 자동화 완료 | PASS |  |  |
| UI-55 | TC10 | 단수 카운터 - 직접 입력 경계값 | 경계값 | `test_ui_55_direct_input_boundaries` | 실행 대기 | PASS |  |  |
| UI-56 | TC10 | 정보 탭 - 프로젝트 요약 표시 | 시나리오 | `test_ui_56_summary_matches_actual_values` | 실행 대기 | PASS |  |  |
| UI-57 | TC10 | 정보 탭 - 진행 사진 기록 | 시나리오 | `test_ui_57_progress_photo` | 실행 대기 | PASS |  |  |
| UI-58 | TC10 | 정보 탭 - 실 사용량 표시 | 시나리오 | `test_ui_58_linked_yarn_shown` | 실행 대기 | PASS |  |  |
| UI-59 | TC10 | 정보 탭 - 사용 바늘 표시 | 시나리오 | `test_ui_59_linked_needle_shown` | 실행 대기 | PASS |  |  |
| UI-60 | TC10 | 정보 탭 - 사용 도구 표시 | 시나리오 | `test_ui_60_linked_tool_shown` | 실행 대기 | PASS |  |  |
| UI-61 | TC10 | 정보 탭 - 게이지 기록 연결과 해제 | 상태 전이 | `test_ui_61_gauge_record_link_and_unlink` | 실행 대기 | PASS |  |  |
| UI-62 | TC10 | 정보 탭 - 작업 메모 기록 | 시나리오 | `test_ui_62_work_memo_saved_and_persists` | 실행 대기 | PASS |  |  |
| UI-63 | TC10 | 정보 탭 - 관련 스킬 표시 | 시나리오 | `test_ui_63_related_skills_shown_and_navigable` | 실행 대기 | PASS |  |  |
| UI-64 | TC11 | 재방문 - 앱 종료 후 작업 상태 보존 | 상태 전이, 시나리오 | `test_ui_64_state_survives_app_restart` | 실행 대기 | PASS |  |  |
| UI-65 | TC12 | 실 등록 - 폼 검증 포함 | 시나리오, 에러 기대 | `test_ui_65_register_yarn` | 실행 대기 | PASS |  |  |
| UI-66 | TC12 | 바늘 등록 - 폼 검증 포함 | 시나리오, 에러 기대 | `test_ui_66_register_needle` | 실행 대기 | PASS |  |  |
| UI-67 | TC12 | 도구 등록 - 폼 검증 포함 | 시나리오, 에러 기대 | `test_ui_67_register_tool` | 실행 대기 | PASS |  |  |
| UI-68 | TC12 | 실과 바늘 - 프로젝트 연결과 해제 | 상태 전이 | `test_ui_68_link_and_unlink_yarn_and_needle` | 실행 대기 | PASS |  |  |
| UI-69 | TC12 | 도구 - 프로젝트 연결과 해제 | 상태 전이 | `test_ui_69_link_and_unlink_tool` | 실행 대기 | PASS |  |  |
| UI-70 | TC13 | 실 수정 - 창고 반영과 스냅샷 비전파 | 상태 전이 | `test_ui_70_yarn_edit_does_not_propagate` | 실행 대기 | PASS |  |  |
| UI-71 | TC13 | 바늘 수정 - 창고 반영과 스냅샷 비전파 | 상태 전이 | `test_ui_71_needle_edit_does_not_propagate` | 실행 대기 | PASS |  |  |
| UI-72 | TC13 | 도구 수정 - 창고 반영 | 상태 전이 | `test_ui_72_tool_edit_propagates` | 실행 대기 | PASS |  |  |
| UI-73 | TC14 | 실 삭제 - 미연결 | 상태 전이 | `test_ui_73_delete_unlinked_yarn` | 실행 대기 | PASS |  |  |
| UI-74 | TC14 | 실 삭제 - 연결된 실 (스냅샷 보존) | 상태 전이 | `test_ui_74_delete_linked_yarn_keeps_snapshot` | 실행 대기 | PASS |  |  |
| UI-75 | TC14 | 바늘과 도구 삭제 - 연결 상태 | 상태 전이 | `test_ui_75_delete_linked_needle_and_tool` | 실행 대기 | PASS |  |  |
| UI-76 | TC14 | 창고 도안 삭제 - 프로젝트 복사본 영향 | 상태 전이 | `test_ui_76_delete_library_pattern_keeps_project_copy` | 실행 대기 | PASS |  |  |
| UI-77 | TC15 | 로그아웃 - 게이트 표시와 데이터 비노출 | 상태 전이 | `test_ui_77_logout_shows_gate_and_hides_account_data` | 실행 대기 | PASS |  |  |
| UI-78 | TC16 | 오프라인 생성 - 복구 후 동기화 | 상태 전이, 시나리오 | `test_ui_78_offline_create_then_sync_on_recovery` | 수동 트랙 | PASS |  |  |

**UI 케이스 78건 중 함수가 존재하는 것: 78건 (통합 함수 1개가 UI-04, 05, 06을 함께 담당하고, UI-42와 UI-51은 각각 2개 함수로 분리)**

### FAIL에서 PASS로 뒤집힌 6건

시트에서 실패거나 실패가 예상됐던 6건이 8/29 실행에서 전부 통과했다.

| 케이스 | 시트 상태 (8/24) | 8/29 판정 | 관련 결함 |
| --- | --- | --- | --- |
| UI-17 | FAIL 예상 (미실행) | PASS | SPEC-PROJ-01 이름 1~30자 |
| UI-33 | FAIL 예상 (미실행) | PASS | DEF-17 lastWorkedAt 미저장 |
| UI-35 | FAIL 예상 (미실행) | PASS | DEF-17 |
| UI-38 | FAIL 예상 (미실행) | PASS | DEF-17 |
| UI-49 | FAIL (8/23, DEF-18) | PASS | DEF-18 보기 모드 드로잉 미표시 |
| UI-51 | 스텝 2 FAIL, 스텝 3 PASS (8/23) | PASS | DEF-19 탭 복귀 시 페이지 초기화 |

이 6건은 스위트 구축 당시 `xfail(strict=True)` 로 묶여 있었다. 결함이 그대로였다면 지금도 실패로 찍혀야 하고, 고쳐졌다면 XPASS로 터져서 마커를 떼라고 알려주는 장치다. 8/26 수정 커밋 이후 마커를 제거했고 현재 스위트에 xfail은 0개다.

**이 6건의 PASS는 자동 재실행이 아니라 회귀 재판정이다.** 시트에 `PASS (8/23)` 로 적힌 11건과는 성격이 다르므로 최종 페이지에서 같은 줄에 세우지 않는다.

---

## 3. API 케이스 (API-01 ~ API-25)

시트 `API 케이스` 탭. 실행 도구는 Postman + psql + Charles다.

| API | 구분 | TC | 영역 | 검증 내용 | 기법 | 판정 기준 | 근거/이력 | 자동/수동 | 판정 근거 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| API-01 | 기본 동작 | TC2 | 인증 | 회원가입 성공 시 계정 생성과 토큰 발급 | 시나리오 | 201 + 토큰 반환 + psql User 행 생성 | 서버 규칙 코드 확인 (8~256자) |  |  |
| API-02 | 기본 동작 | TC2 | 인증 | 비밀번호 길이 규칙의 서버 거부 | 경계값 | 7자와 257자 둘 다 400 (VALIDATION_FAILED) | 8/22 클라 실측과 짝 |  |  |
| API-03 | 기본 동작 | TC2 | 인증 | 중복 이메일 가입 거부 | 에러 기대 | 2회째 거부 응답 | UI-03의 서버 층 확인 |  |  |
| API-04 | 기본 동작 | TC3 | 인증 | 로그인 성공과 실패 자격 거부 | 에러 기대 | 성공 200 + 토큰, 실패 401 (계정 존재 비노출) | 8/22 오류 메시지 동등성 실측 |  |  |
| API-05 | 기본 동작 | TC3 | 인증 | 무토큰 요청의 보호 자원 거부 | 에러 기대 | 401 | DEF-16 조사 중 실측 |  |  |
| API-06 | 기본 동작 | TC4 | 프로젝트 | 목록 조회와 소유자 격리 | 시나리오 | 200 + 소유 항목만 반환 (psql 대조) | 06 AUTH-04 실측 |  |  |
| API-07 | 기본 동작 | TC4 | 프로젝트 | 생성 계약과 필수 필드 | 에러 기대 | 정상 201 + psql 행 생성, 누락 400 | 07 실측 |  |  |
| API-08 | 기본 동작 | TC4 | 프로젝트 | 허용되지 않은 필드 거부 | 에러 기대 | 400 (forbidNonWhitelisted) | 07 실측. DEF-03 재현에 쓴 방법 |  |  |
| API-09 | 기본 동작 | TC4 | 프로젝트 | 타입 오류 거부 | 에러 기대 | 400 | 오탐 정정 이력 (curl 순수 숫자 검증) |  |  |
| API-10 | 기본 동작 | TC5 | 프로젝트 | 수정 반영과 부재 ID 처리 | 시나리오 | 정상 200 + psql 반영, 부재 404 | 07 실측 |  |  |
| API-11 | 기본 동작 | TC6 | 프로젝트 | 삭제의 tombstone 처리 | 상태 전이 | 행 삭제 아닌 deletedAt 마킹 + 목록 제외 | 06 SYNC-06 실측 PASS |  |  |
| API-12 | 기본 동작 | TC10 | 작업 세션 | 세션 저장 검증 규칙 | 에러 기대 | 각각 400 (VALIDATION_FAILED) | 서버 코드 확인. **신규 실행 필요** |  |  |
| API-13 | 기본 동작 | TC10 | 파일 | 업로드 파일과 DB 참조의 정합 | 시나리오 | 참조와 파일이 1:1 (고아 없음) | 07 고아 파일 대조 실측 (0 rows) |  |  |
| API-14 | 기본 동작 | TC15 | 계정 격리 | 타 계정 리소스 직접 접근 거부 | 에러 기대 | 404 또는 403 (존재 비노출) | 치명도 3위 계열. **신규 실행 필요** |  |  |
| API-15 | 기본 동작 | TC4 | 프로젝트 | 단건 조회 | 시나리오 | 200 + 응답 필드가 psql 행과 일치 | **신규 실행 필요** |  |  |
| API-16 | 기본 동작 | TC10 | 작업 세션 | 세션 정상 저장 | 시나리오 | 성공 응답 + WorkSession 행 생성 + 목록 표시 | **신규 실행 필요** |  |  |
| API-17 | 기본 동작 | TC12~14 | 창고 | 재료 CRUD 기본 사이클 | 시나리오 | 각 단계 정상 응답과 DB 반영 | **신규 실행 필요** |  |  |
| API-18 | 결함 회귀 | TC16 | 동기화 | stale PATCH가 기존 세션을 삭제하지 않는지 (DEF-01, 02) | 상태 전이 | 기존 세션 전부 잔존 (하드 삭제 없음) | d0a753a 수정 |  |  |
| API-19 | 결함 회귀 | TC16 | 동기화 | 서버 거부 시 localOnly 보존 (DEF-03) | 에러 기대 | 로컬 보존 + 사용자 안내 표시 | conflict 보존 (eab799d) |  |  |
| API-20 | 결함 회귀 | TC16 | 동기화 | 수정본 거부 시 무통보 폐기 금지 (DEF-04, 12) | 에러 기대 | 폐기 시 사유 안내 표시 | conflict 보존 계열 |  |  |
| API-21 | 결함 회귀 | TC4 | 프로젝트 | RowCounter 없는 프로젝트의 목록 격리 (DEF-08) | 에러 기대 | 200 + 해당 프로젝트만 제외 + 로그 기록 | 06c7a10 수정 |  |  |
| API-22 | 결함 회귀 | TC10 | 스킬 | 서버 삭제 스킬의 캐시 제거 (DEF-09) | 상태 전이 | 삭제된 스킬 미표시 (캐시 프루닝) | 실행 주간 재확인 예정 |  |  |
| API-23 | 결함 회귀 | TC10 | 파일 | 창고 경로 도안의 서버 파일 키 (DEF-13) | 시나리오 | null 아님 | a74945a 수정 |  |  |
| API-24 | 결함 회귀 | TC10 | 파일 | 교체 후 서버 드로잉 키 정리 (DEF-14) | 상태 전이 | 잔존 키 없음 | 0109898 수정 |  |  |
| API-25 | 결함 회귀 | TC8 | 프로젝트 | 세션 저장 시 서버 lastWorkedAt 갱신 (DEF-17) | 상태 전이 | 세션 종료 시각으로 갱신 | **8/29 실행 4 passed** (`qa/api-tests/test_07_last_worked_at.py`) |  |  |

**실행 부담 (시트 원문)**: 07 실측 이력이 있는 항목은 이력 인용 가능. 신규 실행 필요 항목은 API-12, 14, 15, 16, 17과 API-25(수정 후)뿐이다.

API-25는 2026-08-29에 구현하고 실행했다. 서버 계약을 소스로 확인한 뒤 라운드트립, 갱신, 정렬, 계약 공백 네 갈래로 나눴고 4건 전부 통과했다. 응답만 보지 않고 psql로 DB 실제값까지 대조한다.

네 번째 테스트는 통과가 곧 방어 부재를 뜻하는 기록용이다. 서버는 워크세션에서 lastWorkedAt을 파생하지 않고 클라이언트가 보낸 값을 그대로 저장한다(`projects.service.ts:1395`). DEF-17 수정이 클라이언트에만 있으므로 다른 클라이언트가 값을 비워 보내면 정렬이 다시 틀어진다. 서버가 파생하도록 바뀌면 이 테스트가 FAIL하고 그때가 계약이 좁혀졌다는 신호다.

---

### API 케이스와 실행 코드 대조 (2026-08-29)

`qa/api-tests` 9개 파일이 25건 중 어디를 덮는지 대조했다. 덮임 판정은 그 케이스의 검증 내용을 실제로 단언하는 테스트가 있는지 기준이다. 부수적으로 지나가기만 하는 것은 부분으로 본다.

| API | 검증 내용 | 담당 테스트 | 상태 |
| --- | --- | --- | --- |
| API-01 | 회원가입 성공 시 계정 생성과 토큰 발급 | `conftest._register` (픽스처) | 부분 |
| API-02 | 비밀번호 길이 규칙의 서버 거부 | `test_10` 경계 4점 | 덮임 |
| API-03 | 중복 이메일 가입 거부 | `test_10` 409 + 코드 확인 | 덮임 |
| API-04 | 로그인 성공과 실패 자격 거부 | `test_10` 성공, 오답, 없는 계정 | 덮임 |
| API-05 | 무토큰 요청의 보호 자원 거부 | `test_06` 401 3건 | 덮임 |
| API-06 | 목록 조회와 소유자 격리 | `test_01` | 덮임 |
| API-07 | 생성 계약과 필수 필드 | `test_09` SYNC-03 (필수 필드 누락은 미검증) | 부분 |
| API-08 | 허용되지 않은 필드 거부 | `test_10` 미지 필드 400 | 덮임 |
| API-09 | 타입 오류 거부 | `test_10` 불리언 자리 문자열 400 | 덮임 |
| API-10 | 수정 반영과 부재 ID 처리 | `test_02` + `test_09` SYNC-03 | 덮임 |
| API-11 | 삭제의 tombstone 처리 | `test_04` | 덮임 |
| API-12 | 세션 저장 검증 규칙 | `test_06` 시간 역전 세션 | 부분 |
| API-13 | 업로드 파일과 DB 참조의 정합 | `test_09` RC-08 | 덮임 |
| API-14 | 타 계정 리소스 직접 접근 거부 | `test_01` | 덮임 |
| API-15 | 단건 조회 | 여러 테스트가 부수적으로 사용 | 부분 |
| API-16 | 세션 정상 저장 | `test_07` | 덮임 |
| API-17 | 창고 재료 CRUD 기본 사이클 | 없음 | 미커버 |
| API-18 | stale PATCH가 기존 세션을 삭제하지 않는지 | `test_11` 부분 전송, 재전송 | 덮임 |
| API-19 | 서버 거부 시 localOnly 보존 | `test_11` 거부 후 상태 보존 (서버 절반) | 부분 |
| API-20 | 수정본 거부 시 무통보 폐기 금지 | `test_11` 값 보존, 자식 보존 | 덮임 |
| API-21 | RowCounter 없는 프로젝트의 목록 격리 | 없음 | 미커버 |
| API-22 | 서버 삭제 스킬의 캐시 제거 | 없음 | 미커버 |
| API-23 | 창고 경로 도안의 서버 파일 키 | 없음 | 미커버 |
| API-24 | 교체 후 서버 드로잉 키 정리 | 없음 | 미커버 |
| API-25 | 세션 저장 시 서버 lastWorkedAt 갱신 | `test_07` 4건 | 덮임 |

집계는 2026-08-29 기준 덮임 15건, 부분 5건, 미커버 5건이다.

초기 대조에서는 덮임 8건, 부분 5건, 미커버 12건이었다. 두 번에 걸쳐 채웠다. 비용이 낮은 인증 계약 5건(API-02, 03, 04, 08, 09)을 `test_10_auth_contract.py` 로, 03의 P1인 RC-01 동기화 유실 3건(API-18, 19, 20)을 `test_11_sync_loss_regression.py` 로 채웠다.

API-19가 부분에 남은 이유는 이 케이스가 클라이언트의 localOnly 보존을 함께 요구하기 때문이다. 서버가 거부하면서 기존 상태를 훼손하지 않는지는 검증했으나, 거부를 받은 클라이언트가 자기 로컬 데이터를 지키는지는 화면과 로컬 저장소가 대상이라 07에서 볼 수 없다.

남은 미커버 5건은 우선순위가 낮아 의도적으로 뺀 것들이다. API-21(DEF-08, RC-04)은 P2, API-22(DEF-09, RC-07)는 P3, API-23과 24(DEF-13, 14)는 03에서 치명도 축 밖 운영 리스크로 분류된 파일 정합성 계열이다. API-17 창고 CRUD가 나머지 한 건이다.

P1만 골라 채운 것은 04의 투자 원칙을 따른 것이다. 자르는 근거가 우선순위에 있다는 점이 남기지 않은 것보다 중요하다.

부분 5건의 승격 여부는 QA가 정한다. 부수적으로 지나가는 것을 커버로 셀지가 판단이고, 이 문서가 다른 문서에 인용될 때 숫자가 달라지는 지점이다.

---

## 4. 1차 사이클과의 계보

05, 06의 케이스 21건이 2차 스위트의 어디로 이어졌는지다. 시트 `1차 사이클 결과` 탭.

| 1차 케이스 (05) | 트랙 | 검증 대상 (02) | 판정 | 발견 결함 | 2차 담당 |
| --- | --- | --- | --- | --- | --- |
| TC-CUJ1-01 | A (CUJ 넓이) | PAT-01 외 | PASS | | 수동 유지 (여정 전문은 05 정본) |
| TC-CUJ2-01 | A (CUJ 넓이) | AUTH SYNC CNT | PASS | | UI-64 |
| TC-CUJ4-01 | A (CUJ 넓이) | PAT-05 CNT-02 | PASS | | UI-51 (스텝 3) |
| TC-CNT01-01 | C (표준) | CNT-01 | FAIL 후 수정 재실행 PASS | DEF-15 | UI-39, UI-54 (자동화 + CI) |
| TC-CNT02-01 | C (표준) | CNT-02 | PASS | | UI-52, API-16 |
| TC-CNT03-01 | C (표준) | CNT-03 | FAIL | DEF-08 | API-21 |
| TC-SYNC01-01 | C (표준) | SYNC-01 02 04 07 | PASS | | UI-78 |
| TC-SYNC06-01 | C (표준) | SYNC-06 07 | PASS | | API-11 |
| TC-SYNC08-01 | B (P1 심층) | SYNC-08 | FAIL | DEF-01 | API-18 |
| TC-SYNC08-02 | B (P1 심층) | SYNC-08 | FAIL | DEF-02 | API-18 |
| TC-SYNC09-01 | B (P1 심층) | SYNC-09 | FAIL | DEF-03 | API-19 |
| TC-SYNC10-01 | B (P1 심층) | SYNC-10 | FAIL | DEF-04 | API-20 |
| TC-AUTH02-01 | C (표준) | AUTH-02 | PASS | | 수동 유지 (토큰 만료 설정 필요) |
| TC-AUTH04-01 | B (P1 심층) | AUTH-04 | FAIL | DEF-05, 06 | UI-77, API-06 |
| TC-AUTH05-01 | B (P1 심층) | AUTH-05 | FAIL (부분) | DEF-07 | UI-77 |
| TC-LINK01-01 | C (표준) | LINK-01 PAT-03 | FAIL | DEF-10 | UI-45 |
| TC-LINK03-01 | C (표준) | LINK-03 | FAIL | DEF-09 | API-22 |
| TC-LINK05-01 | C (표준) | LINK-05 | PASS | | UI-70, 71, 74 |
| TC-PAT02-01 | C (표준) | PAT-02 | PASS | | UI-40, UI-41 |
| TC-PAT05-01 | C (표준) | PAT-05 | PASS | | UI-51 (스텝 3) |

1차 집계는 실행 21건, PASS 12, FAIL 9다 (SYNC-05는 단위 테스트 통과 확인으로 대체). 트랙 A 나머지 1건과 실행 기록 전문은 06이 정본이다.

---

## 5. 남은 판단 (QA가 채운다)

1. 2절과 3절의 `자동/수동`, `판정 근거` 두 열 전건
2. ~~시트 `상태` 열이 8/24 기준이라 8/25~26에 들어온 Appium 스위트를 반영하지 않는다.~~ 2026-08-29 해소. `자동 실행 판정 (8/29)` 열을 새로 두어 반영했다. 시트 상태 열은 발견 시점 구분을 위해 그대로 남겼다
3. UI-04, 05, 06을 함수 하나로 합친 것이 케이스 추적성에 문제가 되는지 (실패 시 세 케이스 중 어느 쪽인지 구분 가능한가)
