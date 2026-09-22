# 로컬 방식과 온라인 방식: 차이와 구조

작성 2026-09-01. 기준은 커밋 f93aacc 코드. 앱은 실행 시점에 두 방식 중 하나로 조립되고, 실행 중에 바뀌지 않는다. 동작 정의의 근거는 02_functional_spec.md SPEC-SYNC 11건이며, 이 문서는 그 규칙이 어느 코드에서 어떻게 작동하는지를 학습용으로 풀어 쓴 것이다.
작성: Claude (사실 조사). 확인 필요 항목은 마지막 절.

## 결론

1. 방식은 환경변수 하나로 갈린다. KNITGETHER_API_BASE_URL이 있으면 온라인, 없으면 로컬이다. 실기기를 아이콘으로 실행하면 환경변수가 없어도 http://haeun.local:3000/api/v1로 폴백해 온라인이 된다.
2. 로컬 방식은 서버가 없는 독립 앱이다. 로그인 자체가 불가능하고 샘플 데이터가 시드된다. 온라인 방식은 서버가 원본이고 기기는 계정별 캐시다.
3. "오프라인 테스트"는 로컬 방식이 아니라 온라인 방식에서 네트워크를 끊은 상태를 뜻한다. 두 방식의 저장 위치가 달라 데이터가 섞이지 않는다.

## 1. 방식 결정

AppRepositoryContainer.makeDefault(환경변수)가 결정한다.

```
KNITGETHER_API_BASE_URL 있음?
  ├ 예 → 온라인 방식 (OfflineFirst + Remote)
  └ 아니오
      ├ 시뮬레이터 → 로컬 방식
      └ 실기기 → http://haeun.local:3000/api/v1로 온라인 방식 (하드코딩 폴백)
```

| Xcode 스킴 | KNITGETHER_API_BASE_URL | KNITGETHER_DEV_AUTH_TOKEN | 결과 |
| --- | --- | --- | --- |
| KnitGether Local Offline | 없음 | 없음 | 로컬 방식 |
| KnitGether Local Simulator | http://127.0.0.1:3000/api/v1 | 있음 | 온라인, 개발 토큰으로 dev-user 자동 인증 |
| KnitGether Local Device | http://haeun.local:3000/api/v1 | 있음 | 온라인, 실기기 |
| KnitGether (기본) | 설정됨 | 있음 | 온라인 |
| 실기기 아이콘 실행 | 없음 → 폴백 | 없음 | 온라인, 로그인 필요 (세션 게이트) |

주의: 실기기에서는 로컬 방식으로 들어갈 수 있는 경로가 없다. 서버가 꺼져 있으면 온라인 방식의 캐시 폴백으로 동작한다.

## 2. 한눈에 비교

| 항목 | 로컬 방식 | 온라인 방식 |
| --- | --- | --- |
| 조립 | Local*Repository 직접 | OfflineFirst*Repository(local: Local*, remote: Remote*) |
| 원본(source of truth) | 기기 JSON 파일 | 서버 PostgreSQL |
| 저장 경로 | Application Support/KnitGether/projects.json 등 도메인별 파일 | Application Support/KnitGether/RemoteCaches/<서버 주소 스코프>/<userId>/projects.json 등 |
| 샘플 데이터 | 첫 실행 시 시드(seedSamples 기본 true) | 시드 없음(seedSamples: false) |
| 인증 | 불가. LocalAuthRepository는 register, login, fetchCurrentUser 전부 serverUnavailable을 던진다 | JWT. 개발 토큰 또는 정적 토큰이 있으면 로그인 없이 통과 |
| 세션 게이트 | 없음 | 정적 토큰 없고 세션 없으면 로그인 화면(SPEC-AUTH-07) |
| 계정 분리 | 개념 없음 | 캐시 디렉토리가 userId별. 로그아웃 시 캐시는 남음(AUTH-06 불일치) |
| 동기화 상태 배지 | 표시되나 의미 없음(전부 localOnly) | localOnly, pendingUpload, synced, pendingDelete, conflict |
| 도안 PDF 파일 | 기기 파일 | 서버 저장 + 기기 캐시(pattern-files/) |
| 진행 사진 | LocalProjectProgressPhotoRepository (기기) | RemoteProjectProgressPhotoRepository 원격 전용 + 파일 캐시. OfflineFirst 없음 |
| 게이지 목표 | LocalGaugeTargetRepository (기기) | RemoteGaugeTargetRepository 원격 전용. OfflineFirst 없음 |
| 프로필 | 기기 | 세션 또는 정적 토큰이 있을 때만 OfflineFirst, 없으면 로컬 |
| 다른 기기와 공유 | 백업 JSON 내보내기와 가져오기뿐 | 서버 경유. 조회 시점에 반영 |
| API 테스트 의미 | 없음 | 있음 |
| 오프라인 시나리오 | 해당 없음(항상 오프라인) | 네트워크 차단 상태의 동작이 검증 대상 |

## 3. 온라인 방식의 동작

### 3.1 쓰기 (SYNC-01, 02, 03)

```
saveProject(p)
  1. 롤백 스냅샷 생성
  2. 로컬 저장 (상태: synced/pendingUpload → pendingUpload, 그 외 → localOnly)
  3. 원격 시도 (synced였으면 PATCH, 아니면 POST. baseUpdatedAt 동반)
     ├ 성공 → 로컬을 synced로 갱신
     ├ URLError 또는 5xx → 지연(defer). 로컬은 pending 유지, 오류를 삼킨다
     ├ 409 PROJECT_CONFLICT → 롤백 후 서버본 캐시, 오류 전파 (SYNC-11 v2.2)
     └ 그 외 4xx → 롤백 후 오류 전파 (서버 거부)
```

실패 분류 함수가 shouldDefer다. URLError와 상태 코드 500 이상만 지연이고 나머지는 거부다. 이 한 줄이 SYNC-09(거부 시 로컬 보존)와 SYNC-10(거부 사실 안내)의 판정 지점이었다.

### 3.2 읽기 (SYNC-04, 05, 07)

```
fetchProjects()
  1. syncPendingChanges()     ← pending 항목 업로드 시도. 재개는 여기서만 일어난다
  2. 원격 전체 조회
     ├ 성공 → 로컬 캐시 갱신. 서버에 없는 synced 항목은 제거(pruningStaleEntries).
     │        needsUpload 상태 항목은 원격본으로 덮지 않는다
     └ 지연성 실패 → 로컬 반환 + 캐시 폴백 플래그 (화면에 배너)
        단 로컬도 파일도 없으면 오류를 던진다
  3. 로컬 반환
```

앱 재실행 직후 자동 재개는 없다. 목록을 열어야 pending 업로드가 다시 시도된다.

### 3.3 삭제 (SYNC-06)

로컬 tombstone을 먼저 만든다. localOnly면 즉시 물리 제거하고, 아니면 원격 삭제가 성공했을 때만 물리 제거한다. 원격이 거부(4xx)하면 복원한다. 404도 거부로 취급되므로, 다른 기기에서 이미 지운 프로젝트를 이 기기에서 지우면 404로 복원됐다가 다음 조회의 캐시 정리(pruningStaleEntries)에서 사라진다(코드 읽기 기준, 실측 없음). 404를 이미 삭제된 것으로 보는 처리는 자식 레코드(작업 세션 등) 삭제 경로(handleChildDeleteFailure)와 도안, 스킬, 사전 저장소에만 있다.

### 3.4 상태 전이

```
              저장(오프라인)            저장(온라인 성공)
  (없음) ───────────→ localOnly ────────────────→ synced
                          │ 조회 시 업로드 성공        │ 수정 저장
                          └────────────────→ synced ←─┘ (pendingUpload 경유)
  synced ── 수정 저장 ──→ pendingUpload ── 성공 ──→ synced
  pendingUpload ── 서버 거부(4xx) ──→ conflict (확인 필요 배지)
  synced ── 삭제 ──→ pendingDelete ── 원격 성공 ──→ (제거)
  synced ── 저장 시 409 ──→ (로컬은 서버본으로 교체, synced) + 안내
```

conflict 상태는 두 뜻으로 쓰인다. 업로드가 거부된 항목(SYNC-09, 10 수정 반영)과 낙관적 잠금 충돌의 배지 이름이 같다. 낙관적 잠금 충돌은 롤백 후 서버본이 synced로 들어가므로 conflict 상태가 남지 않는다. 배지 의미가 하나로 읽히도록 정리할지는 판단 대상.

### 3.5 역방향(서버 → 기기)

- 푸시 없음. 다른 기기의 변경은 이 기기가 조회할 때 반영된다.
- 변경분 조회(since) 없음. 매번 전체 조회다. 7/4 설계서의 GET /sync?since=는 미구현이다.
- 서버에서 삭제된 항목은 조회 시 로컬에서도 제거된다(pruningStaleEntries: true). 단 needsUpload 상태 항목은 보호된다.
- 다른 기기가 먼저 수정한 프로젝트를 이 기기가 저장하면 409로 막힌다(f93aacc). 카운터 개별 API, 작업 세션, 창고 항목에는 이 검사가 없다.

### 3.6 도메인별 오프라인 지원 범위

| 도메인 | OfflineFirst | 오프라인에서 |
| --- | --- | --- |
| 프로젝트, 도안, 창고(실, 바늘, 도구), 스킬, 사전, 프로필, 게이지 기록 | 있음 | 생성과 수정과 삭제 가능, 조회 시 재개 |
| 진행 사진 | 없음 (원격 전용, 파일 캐시만) | 생성 불가. 이미 캐시된 사진만 표시 |
| 게이지 목표(스와치, 측정) | 없음 (원격 전용) | 불가 |
| 실과 바늘 추가 연결 (LINK-07) | 온라인 필수로 구현 | 불가. 기획 기준과 불일치 확정(02) |

## 4. 로컬 방식의 특성

- 첫 실행에 SampleData가 시드된다. 온라인 방식과 달리 빈 상태를 보려면 파일을 지워야 한다.
- 계정, 로그인, 세션 게이트가 전부 없다. 설정의 계정 카드에서 로그인하면 "서버에 연결할 수 없다" 계열 오류가 난다.
- 파일 경로는 온라인 캐시와 다른 디렉토리라 두 방식의 데이터가 섞이지 않는다.
- 기기 밖으로 데이터를 옮기는 수단은 설정의 백업 JSON뿐이다.

## 5. 방식 사이의 이동

로컬 방식에서 쓰던 데이터는 온라인 방식으로 자동 이관되지 않는다. 경로가 다르기 때문이다. 유일한 경로는 로컬 방식에서 백업 JSON을 내보내고 온라인 방식에서 가져오기다. 가져오기는 projectRepository.saveProject를 타므로 온라인 방식에서는 OfflineFirst를 거쳐 서버까지 올라간다(DataBackupExportViewModel.swift:366). 기존 id와 겹치면 importSyncStatus가 상태를 정한다.

## 6. QA 관점

- 오프라인 시나리오(TC16, UI-78, API-18~20)는 온라인 방식 + 네트워크 차단이다. 로컬 방식으로 돌리면 아무것도 검증하지 않는다.
- API 계약 테스트는 온라인 방식만 의미가 있다. 로컬 방식의 결함은 화면과 파일 저장에서만 나온다.
- 경계 케이스는 shouldDefer의 양쪽이다. 5xx와 URLError(지연), 400과 404와 409(거부). Charles로 각 코드를 주입해 로컬 파일이 어떻게 되는지 보는 것이 07 문서의 방식이다.
- 도메인별 오프라인 지원 범위가 달라서, "오프라인에서 된다"는 문장은 도메인을 붙여야 참이다. 진행 사진과 게이지 목표는 안 된다.
- 실기기에서 서버를 끈 채 아이콘으로 실행하면 로컬 방식이 아니라 온라인 방식의 캐시 폴백이다. 이 차이를 모르면 "실기기에서 오프라인 저장이 된다"를 잘못 판정한다.

## 7. 확인 필요

- 실기기 폴백 주소 http://haeun.local:3000/api/v1가 바이너리에 하드코딩되어 있다(AppRepositoryContainer.swift standaloneDeviceAPIBaseURL). 배포 빌드에도 들어간다. 이대로 둘지.
- conflict 배지가 두 의미(업로드 거부, 낙관적 잠금)로 쓰이는 점을 스펙에 명시할지.
- 로컬 방식의 샘플 시드가 제품 동작인지 개발 편의인지. 제품이라면 온보딩 직후 샘플이 보이는 것이 기획 의도인지.
- 백업 가져오기에서 id가 겹칠 때의 규칙(importSyncStatus)은 이 문서에서 읽지 않았다. 별도 확인.
- 3.3의 삭제 404 복원 동작은 관찰 등록 후보다(14 문서). 다른 기기에서 지운 항목이 이 기기에서 잠깐 되살아났다 사라지는 표시 정합성 문제. 실측으로 확인한 뒤 판정.
