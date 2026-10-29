# 2026-10-29 GitHub·PDF 최종 제출 검수

## 검수 대상과 변경

- 시작 main: `00e7de2829e3d4cb8bb5a59e0b1d43bf876ab46a` (PR #51 병합).
- GitHub 제출 진입점: 루트 README → GitHub QA 포트폴리오 / 14쪽 PDF.
- README에 두 제출 자료 링크, 대표 검증 사례, 담당 역할을 추가했다.
- PDF 첫 페이지의 내부 제출 마감일·문서 커밋 설명을 검증 목적과 역할 구분 요약으로 교체했다. 기존 사례, 실행 수치, 미검증 범위는 유지했다.
- 저장소에 포함된 Pretendard와 기존 ReportLab 빌더로 PDF를 재생성했다. 상대 증거 링크는 위 main 커밋에 고정했다. 해당 커밋에는 링크 대상 증거가 모두 존재한다.

## 검수 방법

원본과 최종 PDF 각각 14쪽을 PNG로 렌더링했다. 원본 전 페이지와 최종 변경 페이지를 직접 확인하고, 최종 전 페이지의 렌더링 비교로 수정 범위를 대조했다. 제목·본문·표·이미지·각주·페이지 번호가 겹치거나 페이지 경계에서 잘리지 않는지 확인했다. 한글 본문은 선택 가능한 텍스트이며 사용한 Pretendard 글꼴은 포함되어 있다.

README, GitHub 요약, PDF 원본 Markdown의 로컬 링크·이미지와 제목 앵커를 대조했다. PDF 링크의 고정 커밋 파일 존재, PDF의 한글 추출·페이지 수·해시, 후속 검증 JSON의 결과 건수는 [기계 대조 결과](submission-audit.json)에 기록했다. 이전 10/28 감사 JSON의 PDF 해시는 당시 파일에만 해당한다.

## 결과 해석

- GitHub와 PDF는 이직용 QA 사례 제출물로 정리되었다. 제품 전체 릴리즈 승인을 뜻하지 않는다.
- 사용자 기획·QA 판단 및 기존 직접 수행과 Codex의 후속 구현·시험·판정을 구분했다.
- 실제 HTTP+PostgreSQL 40 PASS, UI-03 A12+B12=24 PASS는 10/26 원본 기록의 대조다. 오늘 제품 테스트를 새로 실행한 결과가 아니다.
- Windows 서버 회귀 132 PASS / 15 FAIL과 경로 호환성 문제는 10/28 기록과 제출 PDF에 유지했다. 이 검수에서 제품 코드를 변경하거나 실패를 통과로 바꾸지 않았다.
- iOS/실물 iPhone 전체 회귀, 실제 DB E2E 재실행, TestFlight/운영 배포, 장기 부하 검증은 오늘 수행하지 않았다.

## 재현

저장소 루트에서 포함된 글꼴과 ReportLab을 사용한다.

```sh
KNITGETHER_PDF_REF=00e7de2829e3d4cb8bb5a59e0b1d43bf876ab46a python3 docs/qa/submission/tools/build_pdf.py
pdftoppm -png output/pdf/knitgether_qa_portfolio.pdf /tmp/knitgether-page
git diff --check
```

PDF 생성 시각 등 메타데이터로 바이트 해시는 재생성마다 달라질 수 있다. 내용과 렌더링은 별도로 대조한다.
