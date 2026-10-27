# 문서 안내

포트폴리오 본문은 [뜨개더 QA 포트폴리오](github-guide.md)입니다. 이 폴더에는 이전 판본과 증거, PDF 생성 도구를 함께 보관합니다.

| 자료 | 용도와 기준 |
|---|---|
| [QA 포트폴리오](github-guide.md) | 2026-10-27 완료 기준. 최신 QA와 main 병합 근거 |
| [기존 포트폴리오 본문](portfolio.md) | 초기 QA 사례와 날짜별 후속 이력. 사용자 수행과 Codex 수행 구분 |
| [기존 PDF](../../../output/pdf/knitgether_qa_portfolio.pdf) | 10월 초 사례 중심의 기존 판본. 최신 후속 결과 전체를 포함하지 않음 |
| [최종 QA 보고서](../../../qa-runs/2026-10-26-completion/report.md) | 환경·커밋·발견·계층별 결과·한계 |
| [기존 화면 촬영](evidence/2026-10-04/README.md) | 10월 4일 설치 앱 촬영. 당시 소스 커밋 일치 미확인 |
| [QA 상세 기록](../portfolio/README.md) | 요구사항·설계·수동 수행·결함·RTM 원본 |

## 기존 PDF 다시 만들기

Python과 ReportLab이 필요합니다. 저장소 루트에서 실행합니다.

```sh
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 `portfolio.md`를 읽으며 본문을 덮어쓰지 않습니다. 이 명령만으로 최신 QA 포트폴리오가 PDF에 포함되지는 않습니다. 본문 편집 후 생성하고 전 페이지를 이미지로 점검해야 합니다. 포함된 Pretendard 글꼴의 출처와 이용 조건은 [라이선스](fonts/LICENSE.txt)에 있습니다.

[이전 편집·레이아웃·대조 기록](https://github.com/uhaeun/knitgether-app/blob/96f5b84e2feda41f22edf9400536d48a36c9c5dc/docs/qa/submission/README.md)
