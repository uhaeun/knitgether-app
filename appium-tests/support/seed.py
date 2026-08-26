"""Given 상태를 저장 파일로 직접 만든다.

Given은 검증 대상이 아니라 전제라서 UI로 만들지 않고 최단 경로로 만든다.
필드 구성은 Swift 모델(KnitGether/Models/*.swift)의 필수값을 그대로 따른다.
옵셔널은 생략해도 되지만 memo처럼 비옵셔널인 값을 빠뜨리면 디코딩이 통째로 실패하고
앱이 조용히 샘플 데이터로 폴백한다(LocalSampleRepositories.swift:166).
"""
import os
import uuid
from datetime import datetime, timedelta, timezone

from . import simctl

OWNER = "local-user"


def uid():
    return str(uuid.uuid4()).upper()


def ts(days_ago=0, minutes_ago=0):
    t = datetime.now(timezone.utc) - timedelta(days=days_ago, minutes=minutes_ago)
    return t.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _stamp(obj, at=None):
    at = at or ts()
    obj.setdefault("ownerId", OWNER)
    obj.setdefault("createdAt", at)
    obj.setdefault("updatedAt", at)
    obj.setdefault("syncStatus", "Local Only")
    return obj


class Seed:
    """프로젝트와 창고 항목을 쌓아두었다가 apply()에서 한 번에 기록한다."""

    SAMPLE_DIR = "/Users/yuha/Desktop/Projects/KnitGether/KnitGether/Resources/SamplePatterns"

    def __init__(self):
        self.files = []          # (상대경로, 원본경로) 목록. apply()에서 실제로 복사한다
        self.projects = []
        self.gauges = []
        self.lib = {"yarns": [], "needles": [], "tools": [],
                    "yarnLinks": [], "needleLinks": [], "projectToolLinks": [], "yarnUsages": []}

    # ---------- 창고 ----------
    def yarn(self, name, brand="테스트실브랜드", colorway="아이보리", weight="DK", quantity=5):
        y = _stamp({"id": uid(), "name": name, "brand": brand, "colorway": colorway,
                    "weight": weight, "quantity": quantity, "notes": ""})
        self.lib["yarns"].append(y)
        return y

    def needle(self, name, needle_type="Circular", size="5.0 mm", length="80 cm"):
        n = _stamp({"id": uid(), "name": name, "needleType": needle_type,
                    "size": size, "length": length, "notes": ""})
        self.lib["needles"].append(n)
        return n

    def tool(self, name, type_="Marker", link=None, memo=""):
        t = _stamp({"id": uid(), "name": name, "type": type_, "memo": memo, "usageCount": 0})
        if link:
            t["link"] = link
        self.lib["tools"].append(t)
        return t

    def gauge_record(self, needle="게이지바늘", memo="", stage="beforeWash"):
        """게이지 계산기 기록. 프로젝트에 연결되지 않은 상태로 만든다."""
        at = ts()
        rec = _stamp({
            "id": uid(), "measurementStage": stage,
            "sampleWidthCm": 10.0, "sampleHeightCm": 10.0,
            "stitchCount": 22.0, "rowCount": 30.0,
            "targetWidthCm": 50.0, "targetHeightCm": 60.0,
            "stitchesPer10Cm": 22.0, "rowsPer10Cm": 30.0,
            "targetStitches": 110, "targetRows": 180,
            "needle": needle, "memo": memo, "measuredAt": at,
        }, at)
        self.gauges.append(rec)
        return rec

    # ---------- 프로젝트 ----------
    def project(self, name, *, status="WIP", favorite=False, memo="", current_row=0,
                target_row=None, target_date=None, last_worked=None, started=None,
                sessions=0, row_guides=(), pattern=None, pdf=None, pages=None,
                yarn=None, needle=None, tools=(), skills=()):
        pid = uid()
        at = ts()
        p = _stamp({
            "id": pid, "name": name, "status": status, "isFavorite": favorite,
            "memo": memo, "startDate": started or ts(days_ago=7),
            "relatedSkillIds": list(skills),
            "rowCounter": _stamp({
                "id": uid(), "projectId": pid, "name": "Main Counter", "mode": "simple",
                "currentRow": current_row, "rowInstructions": [],
            }, at),
            "workSessions": [
                _stamp({"id": uid(), "projectId": pid,
                        "startedAt": ts(days_ago=i + 1),
                        "endedAt": ts(days_ago=i + 1, minutes_ago=-30)}, at)
                for i in range(sessions)
            ],
        }, at)

        if row_guides:
            counter_id = p["rowCounter"]["id"]
            p["rowCounter"]["rowInstructions"] = [
                _stamp({"id": uid(), "projectId": pid, "rowCounterId": counter_id,
                        "rowNumber": n, "instructionText": text, "skillTags": ""}, at)
                for n, text in enumerate(row_guides, start=1)
            ]
        if target_row is not None:
            p["rowCounter"]["targetRow"] = target_row
        if target_date:
            p["targetDate"] = target_date
        if last_worked:
            p["lastWorkedAt"] = last_worked
        if pattern:
            copy_id = uid()
            copy = _stamp({
                "id": copy_id, "projectId": pid, "titleSnapshot": pattern,
                "pageCountSnapshot": pages or 8, "copiedAt": at,
            }, at)
            if pdf:
                # 실제 PDF가 있어야 뷰어와 그리기 캔버스가 그려진다
                rel = f"Projects/{pid}/Patterns/{copy_id}/{pdf}"
                copy.update({"fileNameSnapshot": pdf, "localCopyPath": rel})
                self.files.append((rel, os.path.join(self.SAMPLE_DIR, pdf)))
            else:
                copy["fileNameSnapshot"] = f"{pattern}.pdf"
            p["patternCopy"] = copy
        # 실과 바늘은 프로젝트 필드(스냅샷)로만 연결한다. 수정 폼이 만드는 형태와 같게 두어야
        # 정보 탭에 같은 항목이 "외 1개"로 중복 표시되지 않는다.
        if yarn:
            p.update({"yarnId": yarn["id"], "yarnNameSnapshot": yarn["name"],
                      "yarnBrandSnapshot": yarn.get("brand"),
                      "yarnColorwaySnapshot": yarn.get("colorway"),
                      "yarnWeightSnapshot": yarn.get("weight")})
        if needle:
            p.update({"needleId": needle["id"], "needleNameSnapshot": needle["name"],
                      "needleTypeSnapshot": needle.get("needleType"),
                      "needleSizeSnapshot": needle.get("size"),
                      "needleLengthSnapshot": needle.get("length")})
        for t in tools:
            self.lib["projectToolLinks"].append(_stamp({
                "id": uid(), "projectId": pid, "toolId": t["id"], "linkedAt": at}, at))

        self.projects.append(p)
        return p

    # ---------- 기록 ----------
    def apply(self):
        simctl.write_store("projects.json", self.projects)
        simctl.write_store("library.json", self.lib)
        if self.gauges:
            simctl.write_store("gauge-records.json", self.gauges)
        for rel, src in self.files:
            simctl.put_pattern_file(rel, src)
        return self
