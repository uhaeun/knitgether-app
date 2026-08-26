"""레포 안의 고정 경로를 레포 루트 기준으로 계산한다.

절대 경로를 파일마다 적어두면 폴더 이름을 바꾸거나 다른 기기에 체크아웃하는 순간
테스트가 통째로 깨진다. 여기 한 곳에서만 루트를 잡고 나머지는 이 값을 쓴다.
"""
import os

# 이 파일 위치: <repo>/appium-tests/support/paths.py  ->  두 단계 위가 레포 루트
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))

SAMPLE_PATTERNS_DIR = os.path.join(REPO_ROOT, "KnitGether", "Resources", "SamplePatterns")
QA_EVIDENCE_DIR = os.path.join(REPO_ROOT, "docs", "qa", "portfolio", "evidence")
