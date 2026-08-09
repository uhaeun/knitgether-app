#!/bin/zsh
set -e
API=http://localhost:3000/api/v1
AUTH="Authorization: Bearer dev-token"
P=$(uuidgen | tr 'A-Z' 'a-z'); RC=$(uuidgen | tr 'A-Z' 'a-z'); Y=$(uuidgen | tr 'A-Z' 'a-z')

echo "1) 테스트 프로젝트와 실 생성"
curl -s -o /dev/null -w "  project: %{http_code}\n" -X POST "$API/projects" -H "$AUTH" -H "Content-Type: application/json" -d "{\"id\":\"$P\",\"name\":\"QA-LINK-스모크\",\"status\":\"WIP\",\"isFavorite\":false,\"memo\":\"\",\"startDate\":\"2026-08-09T00:00:00.000Z\",\"targetDate\":null,\"finishedAt\":null,\"lastWorkedAt\":null,\"yarnId\":null,\"needleId\":null,\"workspaceDisplayMode\":null,\"workspaceSheetPosition\":null,\"relatedSkillIds\":[],\"rowCounter\":{\"id\":\"$RC\",\"projectId\":\"$P\",\"name\":\"Main\",\"mode\":\"rowGuide\",\"sectionName\":null,\"memo\":null,\"currentRow\":0,\"targetRow\":null,\"rowInstructions\":[]},\"workSessions\":[]}"
curl -s -o /dev/null -w "  yarn: %{http_code}\n" -X POST "$API/library/yarns" -H "$AUTH" -H "Content-Type: application/json" -d "{\"id\":\"$Y\",\"name\":\"스모크실\",\"brand\":\"QA\",\"colorway\":\"Red\",\"weight\":\"DK\",\"quantity\":3,\"notes\":\"\"}"

echo "2) 실 링크 생성, 스냅샷 확인"
link=$(curl -s -X POST "$API/library/projects/$P/yarns/$Y" -H "$AUTH")
echo "$link" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  nameSnapshot:',d['nameSnapshot'],'/ brandSnapshot:',d['brandSnapshot'])"

echo "3) 원본 실 이름 수정 후 링크 목록의 스냅샷 불변 확인 (LINK-05)"
curl -s -o /dev/null -X PATCH "$API/library/yarns/$Y" -H "$AUTH" -H "Content-Type: application/json" -d '{"name":"수정된실"}'
curl -s "$API/library/projects/$P/yarn-links" -H "$AUTH" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  링크 수:',len(d),'/ 스냅샷:',d[0]['nameSnapshot'],'(기대: 스모크실)')"

echo "4) 링크 해제 후 빈 목록 확인"
curl -s -o /dev/null -w "  DELETE: %{http_code}\n" -X DELETE "$API/library/projects/$P/yarns/$Y" -H "$AUTH"
curl -s "$API/library/projects/$P/yarn-links" -H "$AUTH" | python3 -c "import sys,json;print('  링크 수:',len(json.load(sys.stdin)),'(기대 0)')"

echo "5) 제목 선행 도안 생성, 파일 첨부, 중복 첨부 거부"
PAT=$(curl -s -X POST "$API/patterns" -H "$AUTH" -H "Content-Type: application/json" -d '{"title":"제목선행-스모크","designer":"QA","notes":""}')
PID=$(echo "$PAT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['id'])")
echo "$PAT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  생성:',d['title'],'/ fileName:',d['fileName'],'(기대 None)')"
printf '%%PDF-1.4\n%% QA smoke pdf\n' > /tmp/qa_smoke.pdf
curl -s -X POST "$API/patterns/$PID/file" -H "$AUTH" -F "file=@/tmp/qa_smoke.pdf;type=application/pdf;filename=smoke.pdf" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  첨부 후 fileName:',d['fileName'],'(기대 smoke.pdf)')"
curl -s -o /dev/null -w "  중복 첨부: %{http_code} (기대 400)\n" -X POST "$API/patterns/$PID/file" -H "$AUTH" -F "file=@/tmp/qa_smoke.pdf;type=application/pdf;filename=smoke2.pdf"

echo "6) 정리"
curl -s -o /dev/null -w "  pattern 삭제: %{http_code}\n" -X DELETE "$API/patterns/$PID" -H "$AUTH"
curl -s -o /dev/null -w "  yarn 삭제: %{http_code}\n" -X DELETE "$API/library/yarns/$Y" -H "$AUTH"
curl -s -o /dev/null -w "  project 삭제: %{http_code}\n" -X DELETE "$API/projects/$P" -H "$AUTH"
echo "== 신규 API 스모크 완료 =="
