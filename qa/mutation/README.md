# 결함 주입 실험 도구

제품 코드의 일부를 바꾸고 해당 결함을 테스트가 발견하는지 확인하는 로컬 실험입니다. 개인 작업 폴더 대신 별도 체크아웃, 테스트 DB와 전용 시뮬레이터를 사용합니다.

```bash
python3 qa/mutation/run_mutation.py --list
# KG_UDID, KG_DERIVED_DATA_PATH, KG_APP_PATH를 전용 환경으로 설정한 뒤:
python3 qa/mutation/run_mutation.py counter-lower-bound
```

실제 실행에는 Xcode, Node.js, Appium, qa/appium의 Python 환경과 DB가 필요합니다. 서버 실험은 기본 3106 포트를 사용하며 `KG_MUTATION_SERVER_PORT`로 바꿀 수 있습니다. 해당 포트가 비어 있어야 하며 도구가 시작한 서버만 종료합니다. `KG_API_BASE_URL`도 같은 서버를 가리켜야 합니다. 앱 빌드는 KnitGether Local Offline 스킴을 사용합니다. `KG_APP_PATH`는 `KG_DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/KnitGether.app`과 일치해야 하며, 다른 경로이면 실행을 중단합니다.

기대한 케이스의 assertion 실패와 대조 케이스의 통과를 함께 확인합니다. 준비 오류, 누락, SKIP 또는 파라미터별 혼합 결과를 검출 성공으로 세지 않습니다.

2026-10-04 보완: 이 실행이 바꾼 파일만 원래 바이트로 복원하고, 매 실행 별도 결과 파일을 사용합니다. 수정 전에는 사전 확인 실패 뒤에도 git checkout이 실행돼 기존 편집을 지울 수 있었고 ERROR가 검출 성공으로 집계될 수 있었습니다. 도구의 독립 회귀 검증은 수행했으나 이번 검토에서 실제 결함 주입과 앱 재빌드는 실행하지 않았습니다. 강제 종료 시 자동 복원이 끝나지 않을 수 있으므로 별도 체크아웃을 사용합니다.
