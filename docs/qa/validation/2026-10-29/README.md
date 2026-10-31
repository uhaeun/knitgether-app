# 2026-10-29 제출 준비와 추가 검증

> 후속 결과: 10월 31일 개별 조회 계약과 목록 캐시 보존을 보완했습니다. 이 문서의 500·xfail은 당시 관측 이력입니다. [현재 계약·재검증](../2026-10-31/integrity-device/README.md)

기준 제품: [`60c0a708d9f310d1095f99ca1683c83531c0171f`](https://github.com/uhaeun/knitgether-app/commit/60c0a708d9f310d1095f99ca1683c83531c0171f). 시작 main은 `34b3a37408ec4c3d251a5f79ba87fa849d11bbac`입니다. 이 문서의 새 실행은 AI가 구현·실행·판정한 결과입니다. 과거 수동 수행과 iOS 화면은 [포트폴리오](../../submission/github-guide.md)의 해당 시점 기록을 따릅니다.

## 무엇을 보완했는가

1. **목록 결손의 재현 조건:** 기존 pytest의 삭제 상태 변경에 최초 수동 재현과 같은 행 삭제를 추가했습니다. 정상 단수를 22에서 99로 SQL 변경해 최신 값 반환과 DB 무변경도 확인합니다.
2. **남은 500의 표시:** 개별 조회가 500을 반환하는 현상을 정상 회귀 결과로 고정하던 단언을 분리했습니다. 현재는 500 미발생을 기대하는 `xfail(strict=True)` 1개입니다. 현재 실패를 공개하며, 예상과 달리 통과하면 실패 표시를 검토하도록 CI가 알립니다. 최종 복구 응답의 상세 계약은 아직 정하지 않았습니다.
3. **파일 경로 호환성:** 기존 '/' 접두사 판단식을 별도 함수로 추출한 상태에서 Windows 경로의 정상 입력 6개 실패를 재현했습니다. 상대 경로로 루트 내부 여부를 판단하도록 보완했습니다. 정상 키, 한글명, `..inside`, 루트 자체, 상위 이탈, 유사 폴더명, 다른 드라이브·UNC 경로와 실제 파일 읽기·삭제를 검사합니다.
4. **제출 경로:** 대표 사례와 판단을 8쪽 본문으로 통합하고 PDF도 같은 본문에서 생성합니다. 이전 상세 본문은 고정 커밋으로 보존했습니다.

## 로컬 결과

macOS 26.5.1, Node 25.4.0, PostgreSQL 14.18, Python 3.12 환경입니다. 기존 개발 DB를 초기화하지 않고 새 `knitgether_qa_sync11_portfolio_20261029` DB에 마이그레이션을 적용했습니다.

| 항목 | 결과 | 범위 |
|---|---|---|
| 서버 빌드 | 성공 | NestJS 빌드 |
| 서버 회귀 | 180 PASS, 13 suites | 기존 147 + 경로 33. Prisma mock 기반 경로 시험 포함 |
| 실제 HTTP·PostgreSQL | 40 PASS / 0 SKIP | 실제 SQL 읽기·쓰기, 경합·롤백·연관 기록·파일 보존 |
| API·네트워크·DB | 76 PASS / 알려진 실패 1개 | 77개 실행, 실패 1개는 개별 조회 500의 xfail |
| 경로 수정 전 | 27 PASS / 6 FAIL | 추출한 기존 판단식, Windows parser의 정상 키 실패 |

33개 경로 시험은 서버 180개에 포함됩니다. 각 계층의 통과 수를 합산하지 않습니다. 실제 DB 시험의 읽기 순서와 실패 주입은 테스트 훅으로 제어하며, DB 자체를 mock하지 않습니다.

첫 API 실행은 테스트 프로세스에 `FILE_STORAGE_ROOT`를 전달하지 않아 실제 서버 저장 위치와 달랐습니다. 70 PASS·6 FAIL·1 xfail을 얻었고, 6개는 파일 경로 환경 불일치였습니다. 양쪽 값을 맞춘 뒤 77개 전체를 재실행한 결과가 위 표입니다. 원인을 숨기거나 제품 수정으로 처리하지 않았습니다.

[항목별 결과](results.json) / [실제 HTTP·SQL 관측](http-sql-evidence.json)

## 실제 Windows·Linux CI

[Storage path compatibility 실행](https://github.com/uhaeun/knitgether-app/actions/runs/40893614884)에서 Windows와 Ubuntu job이 모두 성공했습니다. Node 22의 각 실제 파일 시스템에서 경로 시험 33개씩을 실행했습니다. 파일 경로 범위의 확인이며 Windows 서버 전체 지원을 선언하는 결과가 아닙니다.

[제품 CI](https://github.com/uhaeun/knitgether-app/actions/runs/40893614591)의 서버·실제 PostgreSQL job도 성공했습니다. API와 iOS job의 최종 상태는 [CI 스냅샷](ci-status.json)의 확인 시점에 따릅니다. 완료되지 않은 실행을 통과로 집계하지 않습니다.

최초 iOS CI의 최종 실패와 이후 보완·재검증은 [10월 31일 후속 기록](../2026-10-31/README.md)에 연결합니다. 위 스냅샷은 당시 확인 시점의 이력으로 유지합니다.

## 다시 실행하기

기본 서버 회귀는 실제 DB 없이 실행할 수 있습니다.

```sh
cd server
npm ci
npx prisma generate
npm run build
npm run test:e2e
```

실제 SQL 검증에는 새 전용 DB를 생성하고 아래 URL을 준비합니다. 예시의 localhost 전용 DB명 제약은 테스트 코드가 검사합니다. 기존 DB reset/drop은 필요하지 않습니다.

```sh
export QA_REAL_DATABASE_URL='postgresql://YOUR_LOCAL_USER@127.0.0.1:5432/knitgether_qa_sync11_your_run'
cd server
DATABASE_URL="$QA_REAL_DATABASE_URL" npx prisma migrate deploy
QA_DB_EVIDENCE_PATH=/tmp/knitgether-db-evidence.json npm run test:db:projects
```

API 회귀는 [API 실행 안내](../../../../qa/api-tests/README.md)를 따릅니다. 이번에는 서버 포트 3307, 동일 DB, 양쪽 `FILE_STORAGE_ROOT=/tmp/knitgether-portfolio-files`, 네트워크 프록시의 `KG_NETGATE_FORWARD_PORT=3307`을 사용했습니다. 각자 환경에서는 전용 경로와 빈 포트를 지정합니다. 테스트가 생성한 합성 계정만 정리하며, 실제 DB 동시성 시험의 합성 기록은 대조를 위해 남깁니다.

## 확인하지 않은 범위

이번 로컬 실행에 새 iOS UI·실물 iPhone·TestFlight·운영 배포는 포함하지 않았습니다. 기존 iOS 화면을 최신 서버 빌드의 전체 E2E 통과로 사용하지 않았습니다. 개별 조회 500, 충돌 재저장 중 통신 실패의 화면 전체 흐름, 전 계정 전환 조합, 장기 부하와 과거 고아 파일 일괄 정리는 남은 범위입니다.

npm 설치 감사는 기존 잠금 파일에서 15개 의존성 항목을 보고했습니다. 제품별 영향은 검증하지 않았으며 이 회차에는 의존성을 갱신하지 않았습니다. 공개 자료에는 인증값·비밀번호·원본 서버 로그·DB dump를 포함하지 않습니다.

## 제출본 검수

PDF는 한글 글꼴을 포함하고 텍스트 선택과 증거 링크를 지원합니다. 전체 페이지 이미지 확인, 본문과 PDF의 수치·역할·범위 대조, 로컬 링크와 이미지 존재 검사를 진행했습니다. 최종 결과는 [제출본 검사](submission-audit.json)에 기록합니다.
