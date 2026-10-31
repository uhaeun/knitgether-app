# 포트폴리오 본문과 PDF

- [QA 포트폴리오 본문](github-guide.md): 대표 사례, 판단, 결과와 한계
- [QA 포트폴리오 (PDF)](../../../output/pdf/knitgether_qa_portfolio.pdf): 통합 포트폴리오에 넣을 뜨개더 3쪽
- [최신 조회·기기 검증](../validation/2026-10-31/integrity-device/README.md): 조회 계약·캐시 보존·실행 조건과 결과
- [앞선 iOS 재검증](../validation/2026-10-31/README.md): 최초 실패·시험 준비 보완·후속 결과
- [서버·DB·API 검증](../validation/2026-10-29/README.md): 계층별 결과와 재현 방법
- [테스트 코드와 실행 결과](../../../README.md): 본문 사례별 코드·결과 링크
- [과거 실행 원본](../history.md): 최초 실패와 반복 실행, 이전 상세 문서

## PDF 생성

Python 3.10 이상과 ReportLab, Pillow가 필요합니다. 글꼴은 포함된 Pretendard를 사용합니다. 이용 조건은 [라이선스](fonts/LICENSE.txt)를 참고합니다.

```sh
python3 -m pip install reportlab pillow
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 `github-guide.md`를 읽습니다. 본문을 바꾸지 않고 페이지·글꼴·표·화면을 PDF에 배치합니다. 생성 후 전체 페이지를 이미지로 확인합니다.

PDF의 저장소 내부 링크는 `KNITGETHER_SUBMISSION_REF`로 지정한 커밋에 고정합니다. 기본값은 `main`이며, 공개하는 PDF는 문서 커밋을 지정해 생성합니다. 보존 자료는 본문의 고정 커밋 URL을 그대로 사용합니다. 실행한 제품 소스의 커밋은 각 보고서 안에 별도로 명시합니다.
