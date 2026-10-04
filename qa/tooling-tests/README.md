# QA 도구 자체의 회귀 확인

앱과 서버에 요청하지 않고 테스트 도구의 판정과 파일 복원을 확인합니다. 제품 테스트 통과 건수에 더하지 않습니다.

저장소 루트에서 실행합니다.

```bash
qa/appium/.venv/bin/python -m pytest qa/tooling-tests -q
node qa/tooling-tests/check-postman.cjs
```

첫 명령은 Appium Python 의존성, 두 번째는 server/node_modules의 TypeScript와 DTO 검증 라이브러리가 필요합니다. 두 번째 명령은 서버의 실제 SaveProjectDto를 불러와 요청을 검증하지만 API와 DB에는 연결하지 않습니다.
