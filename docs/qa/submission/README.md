# 제출 자료 안내

- [QA 포트폴리오 본문](github-guide.md): 대표 사례, 판단, 결과와 한계
- [제출 PDF](../../../output/pdf/knitgether_qa_portfolio.pdf): 같은 본문을 8쪽으로 편집
- [최신 iOS 재검증](../validation/2026-10-31/README.md): 최초 실패·시험 준비 보완·후속 결과
- [서버·DB·API 검증](../validation/2026-10-29/README.md): 계층별 결과와 재현 방법
- [이전 기술 상세](technical-summary.md): 후속 충돌 보호와 단위 정책의 당시 실행

## PDF 생성

Python 3.10 이상과 ReportLab, Pillow가 필요합니다. 글꼴은 포함된 Pretendard를 사용합니다. 이용 조건은 [라이선스](fonts/LICENSE.txt)를 참고합니다.

```sh
python3 -m pip install reportlab pillow
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 `github-guide.md`를 읽습니다. 본문을 바꾸지 않고 페이지·글꼴·표·화면을 PDF에 배치합니다. 생성 후 전체 페이지를 이미지로 확인합니다.

증거 링크의 기준 커밋은 `KNITGETHER_PDF_REF`로 지정합니다. 기본값은 이번 제품 수정 커밋입니다. 새 본문과 실행 보고서는 기본 브랜치로 연결하며, 이전 증거는 고정 커밋으로 연결합니다. 새로운 실행 보고서의 제품 기준은 보고서 안에 별도로 명시합니다.
