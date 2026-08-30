# appium-tests

KnitGether iOS 앱을 iOS 시뮬레이터에서 Appium(XCUITest 드라이버)으로 조작하는 UI 회귀 스위트다. 테스트 파일 18개, 테스트 함수 78건이며 pytest로 돈다. 세션은 스위트 전체에서 하나를 재사용하고, 케이스 간 격리는 시뮬레이터 컨테이너의 저장 파일을 지우고 다시 쓰는 방식으로 한다. 이 스위트는 CI(`.github/workflows/`)에 포함되지 않으며 로컬에서만 실행한다.

## 사전 조건

이 값들은 `conftest.py`와 `support/`에서 읽은 것이다. 기본값은 환경변수로 바꿀 수 있다.

| 항목 | 값 | 출처 |
|---|---|---|
| Xcode | 26.6 (이 저장소를 마지막으로 돌린 기계 기준) | `xcodebuild -version` |
| 시뮬레이터 | iPhone 17 Pro Max, UDID `3E4280D4-3E27-42E0-9C35-E84B24E08BD1` | `support/simctl.py`, `KG_UDID`로 변경 |
| 앱 빌드 | DerivedData에서 가장 최근 `KnitGether.app` (Debug-iphonesimulator) | `conftest.py`, `KG_APP_PATH`로 변경 |
| Appium 서버 | `http://127.0.0.1:4723`, 로컬 설치 Appium 3.1.2, xcuitest 드라이버 12.3.4 | 주소는 `conftest.py`, 버전은 실행 기계 실측 (최초 실행 당시 버전은 확인 필요) |
| Python | 3.14.6 (`.venv/pyvenv.cfg`) | Appium-Python-Client 6.0.0, pytest 9.1.1, pillow, requests |
| 서버 | `http://127.0.0.1:3000/api/v1`, `server` 마커가 붙은 케이스(4개 파일, 11건)만 필요 | `KG_API_BASE_URL`로 변경 |
| 오프라인 케이스 | `support/netgate.py`가 3999 포트 TCP 프록시를 띄워 3000으로 넘긴다 | tc16 |

번들 ID는 `com.uhaeun.KnitGether`이고 카메라, 사진 권한은 세션 시작 시 `simctl privacy grant`로 미리 준다. 서버 케이스는 실행마다 고유 이메일로 계정을 새로 만들며 `db:reset-test`는 쓰지 않는다. 서버 기동 방법은 `server/`를 따른다(환경변수 구성은 확인 필요).

## 실행

```bash
cd appium-tests && source .venv/bin/activate   # 또는 pip install -r requirements.txt
pytest tests/ -v                               # 전체 78건
pytest tests/test_tc08_sort_filter.py -v       # 파일 하나
pytest tests/ -v --empty-given                 # 음성 대조: Given 주입을 끄고 돈다. FAIL이 정상
```

`--empty-given`은 이 스위트에 추가한 유일한 pytest 옵션이다. 실패한 케이스의 스크린샷은 `failures/<테스트이름>.png`에 남는다. 50분 넘게 연속 실행하면 WebDriverAgent가 죽은 기록이 있어 파일 단위로 나눠 도는 편이 안전하다([08 5절](../docs/qa/portfolio/08_automation_comparison.md)).

## 구조

- `tests/` TC 그룹별 파일 하나(`test_tc08_sort_filter.py`), 함수 이름은 케이스 ID(`test_ui_33_...`)로 [09 카탈로그](../docs/qa/portfolio/09_test_case_master.md)와 이름으로 대응된다.
- `pages/` 페이지 오브젝트 12개와 공통 부모 `base_page.py`. 로케이터는 페이지 밖으로 새지 않고, 이동은 도착 확인까지 한 메서드가 책임진다.
- `support/` 시뮬레이터 조작(`simctl.py`), Given 시딩(`seed.py`), 서버 계정 유틸(`server_api.py`), 네트워크 열화 프록시(`netgate.py`), 경로(`paths.py`), 화면 문구 상수(`texts.py`).
- `conftest.py` 드라이버 풀(`DriverPool`), 앱 세션(`AppSession`), 픽스처 `kg`, `kg_server`, `kg_offline`, `onboarding`, `netgate`, 실패 스크린샷 훅.

## 알려진 제약

- **fullReset**은 앱 재설치가 아니라 시뮬레이터 전체 초기화라 WebDriverAgent까지 지운다. 온보딩 케이스 하나만 쓰고, 재시도에서는 `full_reset=False`로 떨어뜨려 버틴다. 앱만 지우고 다시 까는 방식으로 바꾸는 게 근본 수정이다.
- **접근성 식별자**가 없는 오버레이 메뉴 항목은 좌표 탭으로 누르며 확률적으로 유실된다(15회 중 3회 실패 실측). 앱 쪽에 식별자를 붙여야 사라진다.
- **음성 대조의 사각**: `--empty-given`은 파일 시딩만 끄므로 서버 시딩에 기대는 서버 케이스에는 신호를 주지 못한다. 서버 시딩까지 끄는 스위치가 필요하다.
- 시뮬레이터에 카메라 피드가 없어 실기기 전용 케이스 1건은 skip이다.

세 숙제의 배경과 진단 과정은 [08 5절](../docs/qa/portfolio/08_automation_comparison.md), 나머지 부채는 [13 6절](../docs/qa/portfolio/13_automation_showcase.md)에 있다.

## 문서

- [09_test_case_master](../docs/qa/portfolio/09_test_case_master.md) 케이스 카탈로그
- [11_execution_results](../docs/qa/portfolio/11_execution_results.md) 실행 결과
- [13_automation_showcase](../docs/qa/portfolio/13_automation_showcase.md) 자동화 쇼케이스: 구조 설명, 음성 대조, 결함 주입
