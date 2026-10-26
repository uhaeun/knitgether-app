# 제출용 포트폴리오

[PDF](../../../output/pdf/knitgether_qa_portfolio.pdf)의 본문은 [portfolio.md](portfolio.md)입니다. 사례 설명과 사진은 `portfolio.md`에서 수정합니다. 원본 화면과 실행 환경은 [추가 검증 자료](evidence/2026-10-04/README.md), 기존 수행 근거는 [QA 상세 기록](../portfolio/README.md)에 있습니다.

## PDF 다시 만들기

Python과 ReportLab이 필요합니다. 저장소 루트에서 실행합니다.

```sh
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 본문을 읽어 PDF를 생성하며 본문을 덮어쓰지 않습니다. 포함된 Pretendard 글꼴의 출처와 이용 조건은 [라이선스](fonts/LICENSE.txt)에 있습니다.

생성 후에는 전 페이지를 이미지로 확인해 글자·표가 잘리거나 사진이 분리되지 않았는지 점검합니다. 기존 QA 수행과 Codex의 추가 촬영은 본문에서 구분합니다.

[이전 문서의 편집·레이아웃·대조 기록](https://github.com/uhaeun/knitgether-app/blob/96f5b84e2feda41f22edf9400536d48a36c9c5dc/docs/qa/submission/README.md)
