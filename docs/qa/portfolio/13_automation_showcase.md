# 13_자동화 쇼케이스

> 2026-08-27 리포지토리 실측이다. 모든 수치는 파일과 함수를 직접 세었다.
> **함수가 존재한다는 사실과 통과한다는 판정은 다르다.** 이 문서는 전자만 담는다. 실행 판정은 11과 12가 다룬다.

---

## 0. 무엇이 내 산출물이고 무엇이 아닌가

이 리포지토리에는 두 종류의 테스트가 섞여 있다. 섞어서 세면 숫자가 부풀려지므로 먼저 가른다.

| | 작성 주체 | 규모 | 포트폴리오 대상 |
| --- | --- | --- | --- |
| Appium 스위트 (`appium-tests/`) | QA (직접 작성) | 함수 78, POM 12, support 6 | **예** |
| XCUITest QA 타깃 (`KnitGetherQAUITests/`) | QA (직접 작성) | 실테스트 1(`testDEF15`), POM 3 | **예** |
| 뮤테이션 도구 (`qa/mutation/`) | QA (직접 작성) | 주입 6종 | **예** |
| XCUITest 개발 타깃 (`KnitGetherUITests/`) | AI (개발 단계) | 메서드 23, 파일 20 | 아니오 (회귀 장치로만 활용) |
| Swift 단위 테스트 (`KnitGetherTests/`) | AI (개발 단계) | `@Test` 329, 파일 42 | 아니오 (CI 게이트 회귀 장치) |
| 서버 e2e (`server/test/`) | AI (개발 단계) | `it()` 117, 스펙 13 | 아니오 (CI 게이트 회귀 장치) |
| pytest API (`qa/api-tests/`) | AI (개발 단계) | 파일 6 | 아니오 |
| Postman 컬렉션 | QA | 최상위 요청 12 | 예 (07 도구) |

04에서 "단위 테스트는 재작성하지 않고 CI 게이트에서 회귀 장치로 활용한다"고 선언했고, 이 표가 그 선언의 실제 모습이다. AI가 만든 것을 내 실적으로 세지 않되 버리지도 않는다.

**주의**: 개발 타깃 XCUITest 23건과 단위 329건은 06에서 밝힌 함정의 당사자이기도 하다. AI가 쓴 단위 테스트 하나가 데이터 유실 동작(DEF-03)을 정상으로 단언하고 있었다. 회귀 장치로 쓰되 판정 근거로는 쓰지 않는 이유다.

---

## 1. Appium 스위트 (주력)

### 규모

| 구성 | 수 | 위치 |
| --- | --- | --- |
| 테스트 함수 | 78 (`test_ui_01` ~ `test_ui_78`) | `appium-tests/tests/` |
| 테스트 파일 | 18 (`test_tc01` ~ `test_tc16`, TC10은 a/b/c 분할) | 같음 |
| Page 객체 | 12 | `appium-tests/pages/` |
| support 모듈 | 6 | `appium-tests/support/` |
| 픽스처 | 6 | `appium-tests/conftest.py` |

파일 이름이 TC 그룹(`test_tc08_sort_filter.py`)이고 함수 이름이 케이스 ID(`test_ui_33_recent_work_moves_to_top`)다. 09의 카탈로그와 코드가 이름으로 직접 대응된다.

### Page 객체 12개

`base_page` (공통 조작 28개), `auth`, `onboarding`, `home`, `my_knitting`, `project_form`, `project_info`, `workspace`, `counter_panel`, `pattern_panel`, `work_time_panel`, `library`

04에서 선언한 대로 Page(화면)와 Test(여정)를 분리했다. 화면이 바뀌면 Page만, 시나리오가 바뀌면 Test만 고친다.

### support 모듈 6개

| 모듈 | 역할 |
| --- | --- |
| `simctl` | 시뮬레이터 제어 (13개 함수). 앱 상태 조회, 파일 앱 주입, 재실행 |
| `seed` | Given 상태 주입. 프로젝트, 창고 항목을 코드로 만들어 전제를 통제 |
| `server_api` | 테스트용 서버 직접 호출 |
| `netgate` | 네트워크 차단과 복구 (오프라인 케이스용) |
| `paths` | 리포지토리 루트 기준 경로 해석 |
| `texts` | 화면 문구 상수. 문구가 바뀌면 한 곳만 고친다 |

### 픽스처 6개

`_pool` (세션 스코프 드라이버 풀), `kg` (기본), `kg_server` (서버 필요), `kg_offline` (네트워크 차단), `netgate`, `onboarding` (온보딩 미완료 상태)

드라이버를 세션 스코프 풀로 재사용해 케이스마다 Appium 세션을 새로 여는 비용을 없앴다.

---

## 2. 이 스위트에서 검증 자체를 검증하는 두 장치

전건 PASS는 두 가지를 뜻할 수 있다. 제품이 정상이거나, 테스트가 아무것도 안 보거나. 그 둘을 가르는 장치를 두 개 넣었다.

### 2-1. `--empty-given` 음성 대조

`pytest --empty-given`을 주면 Given 주입을 건너뛴다. 전제가 사라졌으니 테스트는 **FAIL해야 정상**이다. 그래도 PASS하는 테스트는 전제와 무관하게 통과하는 것이므로 검출력이 없다.

```python
parser.addoption(
    "--empty-given", action="store_true",
    help="Given 주입을 건너뛴다. 음성 대조용: 전제가 사라지면 테스트가 FAIL해야 정상이고, "
         "그래도 PASS하는 테스트는 검출력이 없는 것이다.")
```

### 2-2. 뮤테이션 테스트 (결함 주입 6종)

제품 코드에 고장을 하나씩 심고 빌드해서, **지정한 케이스만 정확히 빨개지는지** 본다. 엉뚱한 케이스가 같이 터지면 그 테스트는 과잉 결합이라 분리 대상이다.

| 주입 | 심는 고장 | FAIL 기대 케이스 |
| --- | --- | --- |
| `counter-lower-bound` | 카운터 하한을 뷰와 ViewModel **두 층에서 모두** 제거 (DEF-15 재현) | `test_ui_54`, `test_ui_52` |
| `delete-without-confirm` | 삭제 확인창을 건너뛰고 즉시 삭제 | `test_ui_29`, `test_ui_31` |
| `sort-reversed` | 정렬을 뒤집어 오래된 프로젝트가 위로 | `test_ui_34` |
| `favorite-not-pinned` | 즐겨찾기 우선 정렬 제거 | `test_ui_37` 계열 |
| `counter-not-saved` | 단수를 화면에만 반영하고 저장 안 함 | 재실행 보존 케이스 |
| `no-owner-filter` | 서버 목록의 소유자 격리를 **세 층에서 모두** 제거 (where 절, 자식 필터, toResponse) | 계정 격리 케이스 |

`counter-lower-bound`와 `no-owner-filter`가 여러 층을 동시에 무너뜨리는 이유는 이중 방어 때문이다. 한쪽만 깨면 다른 쪽이 막아서 테스트가 안 터지고, 그러면 검출력을 측정할 수 없다. 방어 구조를 먼저 읽고 주입 지점을 정했다.

실행: `python3 qa/mutation/run_mutation.py --all`

---

## 3. XCUITest — 왜 1건만 직접 썼는가

QA 타깃 `KnitGetherQAUITests/`의 실제 테스트는 `testDEF15` 한 건이다. 나머지 3개(`testExample`, `testLaunch`, `testLaunchPerformance`)는 Xcode 템플릿 잔여물이다. POM은 3개(`MyKnittingPage`, `WorkspacePage`, `CounterSheetPage`)다.

1건인 것은 부족이 아니라 선정 결과다.

- **왜 DEF-15인가**: QA 사이클 중 UX 개편이 만든 회귀다. 코드 동결 원칙을 실증한 결함이므로 CI가 상시 감시할 가치가 가장 크다. 판정도 명확하다 (0에서 감소 → 값이 늘면 실패)
- **왜 XCUITest인가**: CI에서 돌릴 것이므로 별도 런타임(Appium 서버, Python 환경) 없이 `xcodebuild` 한 줄로 끝나야 한다
- **왜 나머지는 Appium인가**: 78건은 로컬 실행이고, POM 재사용과 Python 시딩·네트워크 제어가 필요하다

같은 DEF-15 경로를 XCUITest와 Appium 양쪽으로 구현했다. 도구 비교 실측을 위한 것이며, 시트 기록상 XCUITest 37.3초, Appium 32.6초다.

---

## 4. CI 품질 게이트

`.github/workflows/qa-gate.yml`. 트리거는 `fix/qa-cycle-defects` 푸시와 수동 실행이다.

| 단계 | 내용 |
| --- | --- |
| 1 | 시뮬레이터 선택 (사용 가능한 iPhone 자동 탐색, UDID 하드코딩 없음) |
| 2 | `build-for-testing` — 빌드 자체가 깨지면 여기서 멈춘다 |
| 3 | 단위 회귀 — `KnitGetherTests` 전건 (`-parallel-testing-enabled NO`) |
| 4 | DEF-15 UI 회귀 — `KnitGetherQAUITests/DEF_15_RegressionTests/testDEF15` |
| 5 | 실패 시 `.xcresult` artifact 업로드 (`if: always()`) |

**게이트 설계 판단**

- 단위 329건을 통째로 넣은 이유는 AI 작성분이라도 회귀 감지 그물로는 유효하기 때문이다. 판정 근거로 쓰지 않을 뿐이다
- Appium 78건은 CI에 넣지 않았다. Appium 서버와 시뮬레이터 상태 의존이 커서 CI 안정성을 해친다. 로컬 실행 스위트로 유지한다
- `if: always()`로 artifact를 남기는 이유는 실패했을 때가 증거가 가장 필요한 순간이기 때문이다

---

## 5. 이 스위트가 하지 않는 것과 그 이유

| 대상 | 처리 | 이유 |
| --- | --- | --- |
| 카메라 문서 스캔 (UI-42) | 실기기 수동 | 입력을 통제할 수 없어 자동 판정이 성립하지 않는다 |
| 파일 선택기 경로 (UI-40, 41) | 시스템 UI 통과 후만 자동 | 경계 절단 원칙. OS 업데이트마다 바뀌고 앱 코드 밖이다 |
| 오프라인 복구 동기화 (UI-78) | 수동 트랙 | 네트워크 제어 비용이 발견 가치를 넘는다. 치명도 1위지만 자동화 대상은 아니다 |
| P1 악조건 시나리오 (트랙 B 6건) | 수동 유지 | 다중 기기, Charles breakpoint, psql 주입이 얽힌다 |
| 성능 정량 판정 | 제외 | 명세 공백. 1000건 주입 시 정상 동작만 관찰하고 판정 기준은 세우지 않았다 |

---

## 6. 알려진 부채

1. **실행 증거가 없다** — `appium-tests/failures/`가 비어 있고 실행 리포트가 리포지토리에 없다. 78건이 통과하는지 이 문서로는 증명할 수 없다. 스위트 1회 완주 후 결과를 12에 기록해야 한다
2. **`qa/mutation/run_mutation.py`에 절대 경로가 남아 있다** — UDID(`3E4280D4...`)와 DerivedData 해시 경로가 하드코딩돼 있다. 커밋 `27aed16`이 `injections.py`와 `appium-tests/support/paths.py`는 루트 기준으로 바꿨으나 `run_mutation.py`는 빠졌다. 다른 기계에서 돌아가지 않는다
3. **`appium-tests/conftest.py`에 미커밋 변경이 있다** — DerivedData 후보 중 최신 빌드를 고르도록 바꾼 것이다. 알파벳순으로 고르던 기존 방식은 리포지토리를 옮기면 낡은 빌드를 상대로 조용히 테스트가 돌던 함정이었다. 커밋 필요
4. **UI-04, 05, 06이 함수 하나로 합쳐져 있다** — `test_ui_04_05_06_submit_disabled_on_invalid_input`. 실패했을 때 세 케이스 중 어느 쪽인지 구분되지 않는다
5. **미푸시 커밋 10건** — Appium 스위트 전체가 로컬에만 있다

---

## 7. 남은 판단 (QA가 채운다)

1. Appium 스위트 1회 완주 후 78건의 실제 판정 (6절 1번)
2. 뮤테이션 6종 실행 후, FAIL 기대 케이스가 실제로 터지는지와 통제군이 안 터지는지
3. `--empty-given` 전건 실행 후 검출력 없는 케이스 식별
4. 6절 2~4번 부채의 처리 여부와 우선순위
