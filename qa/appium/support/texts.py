"""화면에 보이는 한글 문구 상수.

식별자가 없는 요소(확인창 버튼, 롱프레스 메뉴, 홈 타일, 정보 탭 요약행, 창고 허브 행,
상태 필터 칩)는 문구로 잡을 수밖에 없다. 문구가 바뀌면 여기 한 곳만 고치면 되도록 모은다.
값은 전부 앱 소스와 실제 화면에서 실측한 것이다.
"""

# 공용 버튼
CANCEL = "취소"
DELETE = "삭제"
EDIT = "수정"
SAVE = "저장"
CLOSE = "닫기"

# 탭 도착 판정 문구
TAB_LANDMARK = {
    "홈": "안녕하세요",
    "내 뜨개": "나의 뜨개",
    "창고": "도안과 재료를",
    "도구": "게이지",
    "설정": "계정, 데이터",
}

# 프로젝트 목록
PROJECT_COUNT = "개 프로젝트"          # "n개 프로젝트"
EMPTY_PROJECTS = "아직 등록된 프로젝트가 없어요."
ADD_PROJECT_HINT = "첫 뜨개 프로젝트를 추가해 보세요."
FILTER_ALL = "전체"

# 프로젝트 폼
FORM_ADD_TITLE = "프로젝트 추가"
FORM_EDIT_TITLE = "프로젝트 수정"
SAVE_NEW_PROJECT = "프로젝트 저장"
SAVE_CHANGES = "변경사항 저장"
FAVORITE = "즐겨찾기"
TARGET_DATE_TOGGLE = "목표일 설정"
TARGET_DATE = "목표일"
START_DATE = "시작일"
PROJECT_UPDATED = "프로젝트를 수정했어요"

# 삭제 확인창
DELETE_PROJECT_TITLE = "프로젝트를 삭제할까요?"
DELETE_PROJECT_BODY = "삭제한 프로젝트는 복구할 수 없어요."

# 작업 화면
TAB_WORKING = "뜨는 중"
TAB_INFO = "프로젝트 정보"
PATTERN_EMPTY = "도안이 비어 있어요."
PATTERN_NONE_CHIP = "연결된 도안 없음"
PATTERN_NO_FILE = "PDF 파일이 없어요."
PATTERN_MANUAL_HINT = "수동 도안은 이름만 저장돼요."
MODE_VIEWER = "뷰어 모드"
MODE_DRAW = "그리기 모드"
MENU_DELETE_DRAWING = "그리기 삭제"
STORE_PROMPT_TITLE = "도안창고에 보관할까요?"
STORE_AND_LINK = "도안창고에 보관하고 연결"
LINK_ONLY = "프로젝트에만 연결"
REPLACE_TITLE = "기존 도안을 교체할까요?"
REPLACE_CONFIRM = "교체"
REPLACE_WARNING = "기존 도안에 작성한 드로잉이 삭제돼요"
UNLINK_TITLE = "도안 연결을 해제할까요?"
UNLINK_CONFIRM = "연결 해제"
UNLINK_BODY = "도안 창고의 원본은 삭제되지 않아요"
DELETE_DRAWING_TITLE = "그리기를 지울까요?"
DELETE_DRAWING_BODY = "저장된 그리기 메모는 복구할 수 없어요."
COUNTER_RESET_TITLE = "단수를 리셋할까요?"
COMPLETION_PROMPT_TITLE = "목표 단수에 도달했어요"
COMPLETION_LATER = "나중에"
SHEET_EXPAND = "카운터 시트 펼치기"
SHEET_COLLAPSE = "카운터 시트 접기"
COUNTER_START = "시작 전"
COUNTER_CURRENT = "현재 {}단"
WORK_START = "작업 시작"
WORK_FINISH = "작업 종료"

# 문서 스캐너 (시뮬레이터에서는 isSupported가 true라 스캐너가 열리고 촬영만 실패한다.
# 앱이 준비한 한글 폴백 "문서 스캔을 사용할 수 없어요."는 이 환경에서 실행되지 않는다.)
SCANNER_HINT = "Position the document in view."
SCANNER_CAPTURE_FAIL = "Unable to capture media"

# 정보 탭
INFO_SUMMARY = "프로젝트 요약"
INFO_PROGRESS = "진행"
INFO_SCHEDULE = "일정"
INFO_TOTAL_TIME = "총 작업시간"
INFO_PROGRESS_PHOTO = "진행 사진"
INFO_YARN_USAGE = "실 사용량"
INFO_NEEDLE = "사용 바늘"
INFO_TOOL = "사용 도구"
INFO_GAUGE = "게이지 기록"
INFO_MEMO = "작업 메모"
INFO_SKILLS = "관련 스킬"

# 창고
LIB_PATTERN = "도안 창고"
LIB_YARN = "실 창고"
LIB_NEEDLE = "바늘 창고"
LIB_TOOL = "도구 창고"
LIB_SKILL = "스킬 창고"
DELETE_YARN_TITLE = "실을 삭제할까요?"

# 홈
HOME_TOTAL = "전체 프로젝트"
HOME_WIP = "진행 중"
HOME_DONE = "완성됨"
HOME_ELAPSED = "누적 작업"

# 계정
LOGIN = "로그인"
SIGNUP = "회원가입"
LOGOUT = "로그아웃"
ACCOUNT_ROW = "계정 연동"
GREETING = "안녕하세요"
DUPLICATE_EMAIL = "이미 가입된 이메일이에요"
BAD_CREDENTIALS = "이메일 또는 비밀번호가 맞지 않아요"
