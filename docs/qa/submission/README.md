# 문서 안내

포트폴리오 본문은 [뜨개더 QA 포트폴리오](github-guide.md)입니다. 이 폴더에는 제출 본문과 증거, PDF 생성 도구를 함께 보관합니다.

| 자료 | 용도와 기준 |
|---|---|
| [QA 포트폴리오](github-guide.md) | 2026-10-28 제출 안내. 최신 QA와 main 병합 근거 |
| [제출 포트폴리오 본문](portfolio.md) | 대표 DEF-10/08과 후속 정책·결과·한계. 사용자 판단과 Codex 수행 구분 |
| [제출 PDF](../../../output/pdf/knitgether_qa_portfolio.pdf) | 2026-10-28 재생성, 14쪽. 기존 11쪽에 후속 검증·결과 해석 3쪽 추가 |
| [최종 QA 보고서](../../../qa-runs/2026-10-26-completion/report.md) | 환경·커밋·발견·계층별 결과·한계 |
| [기존 화면 촬영](evidence/2026-10-04/README.md) | 10월 4일 설치 앱 촬영. 당시 소스 커밋 일치 미확인 |
| [QA 상세 기록](../portfolio/README.md) | 요구사항·설계·수동 수행·결함·RTM 원본 |

## 제출 PDF 다시 만들기

Python과 ReportLab이 필요합니다. 저장소 루트에서 실행합니다.

```sh
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 `portfolio.md`를 읽으며 본문을 덮어쓰지 않습니다. 제출 본문과 PDF를 함께 갱신합니다. 생성 후 전 페이지를 이미지로 점검해야 합니다. 이번 검수는 [10/28 결과](../validation/2026-10-28/README.md)와 [기계 대조](../validation/2026-10-28/submission-audit.json)에 기록했습니다. 포함된 Pretendard 글꼴의 출처와 이용 조건은 [라이선스](fonts/LICENSE.txt)에 있습니다.

PDF의 상대 증거 링크를 제출 시점에 고정하려면 생성 전에 `KNITGETHER_PDF_REF` 환경변수를 해당 문서·증거가 존재하는 커밋 SHA로 설정합니다. 기본값은 main입니다. 이번 제출 PDF는 문서 커밋에 고정해 PR 병합 전에도 근거를 열 수 있게 했습니다.

[이전 편집·레이아웃·대조 기록](https://github.com/uhaeun/knitgether-app/blob/96f5b84e2feda41f22edf9400536d48a36c9c5dc/docs/qa/submission/README.md)
