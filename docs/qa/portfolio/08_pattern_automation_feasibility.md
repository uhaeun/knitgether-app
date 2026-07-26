# 도안(Pattern) · 사전(Dictionary) 자동화 가능성 조사 (2026-07-26)

> 쓴 사람: Claude(사실 조사만). **TC 내용·판단은 유하가 직접 작성.**
> 이 문서는 "어느 영역이 UI 자동화가 되고, 안 되면 왜인지"라는 **사실**만 기록한다.

## 결론 요약

| 영역 | UI 자동화 | 근거(사실) |
|---|---|---|
| 사전(Dictionary) | ✅ 됨 (읽기 검증) | 읽기 전용이라 생성 UI가 없어, 테스트가 **API로 용어를 시드**한 뒤 표시·상세를 검증. `testDictionaryTermsSeededViaAPIDisplaySearchAndDetail` 통과 |
| 도안(Pattern) 생성 | ❌ 안 됨 | 추가 경로가 **시스템 PDF 파일 선택(`.fileImporter`)** 또는 **문서 스캔(`DocumentScannerView`)** 뿐. 둘 다 앱 밖 시스템 UI라 XCUITest로 안정적으로 몰 수 없음 (`PatternLibraryView.swift`) |
| 도안(Pattern) 수정/삭제 | △ 조건부 | 수정/삭제 폼엔 접근성 ID가 이미 있음(`library.pattern.*`). 단 **도안이 먼저 존재**해야 하고, 생성이 시스템 피커에 묶여 있어 UI만으로는 선행조건을 못 만듦. API+PDF 업로드로 시드하면 수정/삭제만 자동화 가능(미구현) |

## 사실 근거 (코드)

- `PatternLibraryView.swift`
  - 추가: `.fileImporter(isPresented:allowedContentTypes:[.pdf])` + `.sheet { DocumentScannerView(...) }` — 앱 내 "제목만 입력해서 만들기" 경로 **없음**
  - 수정: `PatternFormView`(제목/디자이너/페이지수/메모) — 접근성 ID 있음(`library.pattern.form.*`, `library.pattern.save`)
  - 상세/삭제: `library.pattern.edit`, 삭제 확인 알림 존재
- 사전은 유저별 데이터(`DictionaryTerm.ownerId`)이고 자동 시드가 없어, 신규 유저는 사전이 비어 있음 → 테스트가 API로 시드해야 의미 있음(그래서 위 방식 채택)

## 그래서 도안은 "수동 TC" 대상

도안 **가져오기(PDF/스캔) 경로**는 시스템 피커 의존이라 자동화 ROI가 낮고 깨지기 쉬움 → **수동 테스트 케이스로 다루는 것이 타당**하다는 것이 이 조사의 결론이다.

> **다음(유하 작성):** 위 사실을 근거로, 도안 가져오기/수정/삭제/재실행 유지에 대한 **수동 TC를 `06_smoke_test_cases.md` 형식으로 직접 작성**한다. (시나리오·기대결과·severity 판단은 본인 몫. 이 문서는 근거 자료로만 참조.)
