#!/bin/zsh
set -e
API=http://localhost:3000/api/v1
AUTH="Authorization: Bearer dev-token"
P=$(uuidgen | tr 'A-Z' 'a-z'); RC=$(uuidgen | tr 'A-Z' 'a-z')
S1=$(uuidgen | tr 'A-Z' 'a-z'); S2=$(uuidgen | tr 'A-Z' 'a-z')

body_s1_only() {
cat << JSON
{
  "id": "$P",
  "name": "QA-SYNC08-회귀검증",
  "status": "WIP",
  "isFavorite": false,
  "memo": "regression probe",
  "startDate": "2026-08-09T00:00:00.000Z",
  "targetDate": null,
  "finishedAt": null,
  "lastWorkedAt": null,
  "yarnId": null,
  "needleId": null,
  "workspaceDisplayMode": null,
  "workspaceSheetPosition": null,
  "relatedSkillIds": [],
  "rowCounter": {
    "id": "$RC",
    "projectId": "$P",
    "name": "Main",
    "mode": "rowGuide",
    "sectionName": null,
    "memo": null,
    "currentRow": 1,
    "targetRow": null,
    "rowInstructions": []
  },
  "workSessions": [
    {
      "id": "$S1",
      "projectId": "$P",
      "startedAt": "2026-08-09T08:00:00.000Z",
      "endedAt": "2026-08-09T09:00:00.000Z",
      "memo": "session-1"
    }
  ]
}
JSON
}

echo "1) 프로젝트 생성 (세션 S1 포함)"
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/projects" -H "$AUTH" -H "Content-Type: application/json" -d "$(body_s1_only)")
echo "   POST /projects -> $code"

echo "2) 개별 API로 세션 S2 추가"
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/projects/$P/work-sessions" -H "$AUTH" -H "Content-Type: application/json" -d "{\"id\":\"$S2\",\"projectId\":\"$P\",\"startedAt\":\"2026-08-09T10:00:00.000Z\",\"endedAt\":\"2026-08-09T10:30:00.000Z\",\"memo\":\"session-2\"}")
echo "   POST work-sessions -> $code"

before=$(curl -s "$API/projects/$P/work-sessions" -H "$AUTH" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d))")
echo "3) PATCH 전 세션 수: $before (기대 2)"

echo "4) S1만 담은 stale PATCH 전송 (구 동작이면 S2가 무이력 삭제됨)"
code=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API/projects/$P" -H "$AUTH" -H "Content-Type: application/json" -d "$(body_s1_only)")
echo "   PATCH /projects/$P -> $code"

after_json=$(curl -s "$API/projects/$P/work-sessions" -H "$AUTH")
after=$(echo "$after_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d))")
has_s2=$(echo "$after_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(any(s['id']=='$S2' for s in d))")
echo "5) PATCH 후 세션 수: $after (기대 2), S2 생존: $has_s2 (기대 True)"

echo "6) 정리: 프로젝트 삭제"
code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API/projects/$P" -H "$AUTH")
echo "   DELETE -> $code"

if [ "$after" = "2" ] && [ "$has_s2" = "True" ]; then
  echo "== SYNC-08 회귀 검증 PASS: 요청 본문에 없는 세션이 보존됨 =="
else
  echo "== SYNC-08 회귀 검증 FAIL =="
  echo "$after_json"
  exit 1
fi
