"""C-2 결함 주입 정의.

전건 PASS는 "제품이 정상"일 수도 "테스트가 아무것도 안 본다"일 수도 있다.
일부러 고장을 심어 지정한 케이스만 정확히 빨개지는지 보면 그 둘이 갈린다.
엉뚱한 케이스가 같이 터지면 그 테스트는 과잉 결합이라 분리 대상이다.
"""
ROOT = "/Users/yuha/Desktop/Projects/KnitGether"

INJECTIONS = {
    "counter-lower-bound": {
        "설명": "카운터 하한을 두 층에서 모두 제거 (DEF-15 재현). "
              "뷰의 버튼 비활성화와 ViewModel의 0 하한이 이중 방어라 한쪽만 무너뜨리면 드러나지 않는다",
        "대상": "app",
        "편집": [
            ("KnitGether/Views/MyKnitting/Workspace/ProjectCounterPanelView.swift",
             "            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterPreviousButton)\n"
             "            .disabled(viewModel.currentRow == 0)\n",
             "            .accessibilityIdentifier(AppAccessibilityID.Workspace.counterPreviousButton)\n"),
            ("KnitGether/ViewModels/ProjectWorkspaceViewModel.swift",
             "        await updateRow(to: max(0, currentRow - 1))",
             "        await updateRow(to: max(0, currentRow + 1))"),
        ],
        "FAIL 기대": ["test_ui_54_lower_bound_stays_at_start",
                     "test_ui_52_simple_mode_increment_and_decrement"],
    },
    "delete-without-confirm": {
        "설명": "삭제 확인창을 건너뛰고 즉시 삭제한다",
        "대상": "app",
        "파일": "KnitGether/Views/MyKnitting/MyKnittingView.swift",
        "찾기": """                    Button(role: .destructive) {
                        projectPendingDeletion = project
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {""",
        "바꾸기": """                    Button(role: .destructive) {
                        Task { await viewModel.deleteProject(project) }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {""",
        "FAIL 기대": ["test_ui_29_delete_via_long_press",
                     "test_ui_31_delete_two_of_three_keeps_rest"],
    },
    "sort-reversed": {
        "설명": "정렬을 뒤집는다. 오래된 프로젝트가 위로 온다",
        "대상": "app",
        "파일": "KnitGether/Repositories/Local/LocalSampleRepositories.swift",
        "찾기": "            return (first.lastWorkedAt ?? first.startDate) > (second.lastWorkedAt ?? second.startDate)",
        "바꾸기": "            return (first.lastWorkedAt ?? first.startDate) < (second.lastWorkedAt ?? second.startDate)",
        "FAIL 기대": ["test_ui_34_start_date_desc_without_history"],
    },
    "favorite-not-pinned": {
        "설명": "즐겨찾기 우선 정렬을 없앤다. 별을 켜도 상단으로 오지 않는다",
        "대상": "app",
        "파일": "KnitGether/Repositories/Local/LocalSampleRepositories.swift",
        "찾기": """            if first.isFavorite != second.isFavorite {
                return first.isFavorite && !second.isFavorite
            }
""",
        "바꾸기": "",
        "FAIL 기대": ["test_ui_37_favorite_pins_to_top"],
    },
    "counter-not-saved": {
        "설명": "단수를 화면에만 반영하고 저장하지 않는다. 재실행하면 사라진다",
        "대상": "app",
        "파일": "KnitGether/ViewModels/ProjectWorkspaceViewModel.swift",
        "찾기": """        let updatedProject = project.updatingRow(to: row)
        await persistRowCounter(updatedProject.rowCounter, updatedProject: updatedProject, errorMessage: "단수를 저장하지 못했어요.")""",
        "바꾸기": """        let updatedProject = project.updatingRow(to: row)
        applyProjectState(updatedProject)""",
        "FAIL 기대": ["test_ui_64_state_survives_app_restart"],
    },
    "no-owner-filter": {
        "설명": "서버 프로젝트 목록의 소유자 격리를 세 층에서 모두 제거. "
              "where 절, 자식 레코드 필터, toResponse의 소유자 확인이 3중 방어라 "
              "한두 층만 지워서는 실제로 새지 않는다 (서버 로그의 Skipped project 로 실증)",
        "대상": "server",
        "편집": [
            ("server/src/projects/projects.service.ts",
             """  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: this.projectInclude(ownerId),""",
             """  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        deletedAt: null,
      },
      include: this.projectInclude(undefined as unknown as string),"""),
            ("server/src/projects/projects.service.ts",
             """    if (
      !project.rowCounter ||
      project.rowCounter.ownerId !== ownerId ||
      project.rowCounter.deletedAt !== null
    ) {""",
             """    if (
      !project.rowCounter ||
      project.rowCounter.deletedAt !== null
    ) {"""),
        ],
        "파일": "server/src/projects/projects.service.ts",
        "찾기": """  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },""",
        "바꾸기": """  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        deletedAt: null,
      },""",
        "FAIL 기대": ["test_ui_77_logout_shows_gate_and_hides_account_data"],
    },
}
