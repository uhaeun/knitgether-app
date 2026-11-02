# 테스트 설계와 실행 근거

- [테스트 설계와 주요 사례](github-guide.md): 사용자 흐름, 우선순위, 수정 전후와 확인 범위
- [사용자 흐름별 TC](../portfolio/05_test_cases.md) / [최초 수동 수행](../portfolio/06_manual_execution.md)
- [목록과 개별 조회, 캐시와 실기기](../validation/2026-10-31/integrity-device/README.md)
- [도안 교체와 페이지 복귀](evidence/2026-10-04/README.md)
- [동시 수정과 미저장 메모](evidence/2026-10-26/README.md)
- [서버와 DB 재실행](../validation/2026-10-29/README.md)
- [전체 코드와 결과](../../../README.md) / [과거 실행 기록](../history.md)

<details>
<summary>PDF와 생성 방법</summary>

[현재 본문의 PDF](../../../output/pdf/knitgether_qa_portfolio.pdf)는 뜨개더 단독 4쪽입니다. 이전 3쪽 버전은 [이전 커밋](https://github.com/uhaeun/knitgether-app/blob/fc17e9e77a1d481cd5e365b12d02d5a7be2a1bd3/output/pdf/knitgether_qa_portfolio.pdf)에 남아 있습니다.

Python 3.10 이상과 ReportLab, Pillow가 필요합니다. 포함된 Pretendard 글꼴의 [라이선스](fonts/LICENSE.txt)를 따릅니다.

```sh
python3 -m pip install reportlab pillow
python3 docs/qa/submission/tools/build_pdf.py
```

스크립트는 `github-guide.md`를 읽습니다. GitHub의 Mermaid 도식과 PDF의 도식은 같은 상태와 확인 위치를 표시합니다. 본문의 근거 링크는 실행 기록의 커밋에 고정했습니다. 이 문서의 수정일을 제품 테스트 실행일로 사용하지 않습니다.

</details>
