# Workspace UX Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the project workspace UX so pattern viewing, row counting, row guidance, work time, memo, and related skill flows feel complete without adding new server domains.

**Architecture:** Keep `ProjectWorkspaceViewModel` as the single mutation/persistence owner. Split the large SwiftUI workspace screen into focused views under `KnitGether/Views/MyKnitting/Workspace/`, and add small tested ViewModel APIs for reset, completion, unlink, and skill tag resolution.

**Tech Stack:** SwiftUI, Swift Testing, existing `ProjectRepository`, `PatternRepository`, `SkillRepository`, existing Nest/Prisma API for project save.

## Global Constraints

- Do not add tool inventory/project tool linking in this step.
- Do not add persisted gauge records or project-linked gauge records in this step.
- Do not add project target date, end date, or D-day fields in this step.
- Do not redesign the full app shell or project list.
- Keep all persistence compatible with the current `ProjectRepository.saveProject` and `PatternRepository` interfaces.
- Avoid server changes in this step.

---

### Task 1: ViewModel Workspace Actions

**Files:**
- Create: `KnitGetherTests/ProjectWorkspaceViewModelTests.swift`
- Modify: `KnitGether/ViewModels/ProjectWorkspaceViewModel.swift`

**Interfaces:**
- Produces: `resetCurrentRow() async`, `completeProject() async`, `unlinkPattern() async`, `resolvedSkillTags(for:) -> [ResolvedSkillTag]`, `currentResolvedSkillTags -> [ResolvedSkillTag]`.
- Consumes: existing `KnittingProject.copy(...)`, `ProjectRepository.saveProject(_:)`, `PatternRepository.fileURL(for:)`, and `SkillRepository.fetchSkills()`.

- [ ] **Step 1: Write failing tests**

Add tests that construct `ProjectWorkspaceViewModel` with in-memory repository fakes and verify:

```swift
@Test func resetCurrentRowPersistsZeroAndKeepsCounterMetadata() async throws {
    let project = ProjectWorkspaceViewModelTests.makeProject(currentRow: 12, targetRow: 40, rowInstructions: [
        ProjectWorkspaceViewModelTests.makeInstruction(rowNumber: 12, text: "K all", skillTags: "K")
    ])
    let repository = ProjectWorkspaceViewModelTests.ProjectRepositorySpy(project: project)
    let viewModel = ProjectWorkspaceViewModel(
        project: project,
        projectRepository: repository,
        patternRepository: ProjectWorkspaceViewModelTests.PatternRepositoryFake(),
        skillRepository: ProjectWorkspaceViewModelTests.SkillRepositoryFake()
    )

    await viewModel.resetCurrentRow()

    #expect(viewModel.currentRow == 0)
    #expect(repository.savedProjects.last?.rowCounter.currentRow == 0)
    #expect(repository.savedProjects.last?.rowCounter.targetRow == 40)
    #expect(repository.savedProjects.last?.rowCounter.rowInstructions.count == 1)
}

@Test func completeProjectPersistsCompletedStatus() async throws {
    let project = ProjectWorkspaceViewModelTests.makeProject(status: .wip)
    let repository = ProjectWorkspaceViewModelTests.ProjectRepositorySpy(project: project)
    let viewModel = ProjectWorkspaceViewModel(
        project: project,
        projectRepository: repository,
        patternRepository: ProjectWorkspaceViewModelTests.PatternRepositoryFake(),
        skillRepository: ProjectWorkspaceViewModelTests.SkillRepositoryFake()
    )

    await viewModel.completeProject()

    #expect(viewModel.project.status == .completed)
    #expect(repository.savedProjects.last?.status == .completed)
}

@Test func unlinkPatternRemovesPatternAndDrawingState() async throws {
    let project = ProjectWorkspaceViewModelTests.makeProject(patternCopy: ProjectWorkspaceViewModelTests.makePatternCopy())
    let repository = ProjectWorkspaceViewModelTests.ProjectRepositorySpy(project: project)
    let viewModel = ProjectWorkspaceViewModel(
        project: project,
        projectRepository: repository,
        patternRepository: ProjectWorkspaceViewModelTests.PatternRepositoryFake(),
        skillRepository: ProjectWorkspaceViewModelTests.SkillRepositoryFake()
    )
    viewModel.drawingData = Data("drawing".utf8)

    await viewModel.unlinkPattern()

    #expect(viewModel.project.patternCopy == nil)
    #expect(viewModel.attachedPatternFileURL == nil)
    #expect(viewModel.drawingData == nil)
}

@Test func resolvedSkillTagsMarksRegisteredAndUnregisteredTags() async throws {
    let project = ProjectWorkspaceViewModelTests.makeProject(rowInstructions: [
        ProjectWorkspaceViewModelTests.makeInstruction(rowNumber: 1, text: "K then YO", skillTags: "K,YO")
    ])
    let viewModel = ProjectWorkspaceViewModel(
        project: project,
        projectRepository: ProjectWorkspaceViewModelTests.ProjectRepositorySpy(project: project),
        patternRepository: ProjectWorkspaceViewModelTests.PatternRepositoryFake(),
        skillRepository: ProjectWorkspaceViewModelTests.SkillRepositoryFake(skills: [
            ProjectWorkspaceViewModelTests.makeSkill(abbreviation: "K", difficulty: "잘 알아요")
        ])
    )

    await viewModel.loadRelatedSkills()
    let tags = viewModel.resolvedSkillTags(for: project.rowCounter.rowInstructions[0])

    #expect(tags.map(\.displayTag) == ["K", "YO"])
    #expect(tags[0].isRegistered)
    #expect(tags[0].level == "잘 알아요")
    #expect(!tags[1].isRegistered)
    #expect(tags[1].level == "미등록")
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:KnitGetherTests/ProjectWorkspaceViewModelTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: fails because the new ViewModel APIs and `ResolvedSkillTag` type do not exist.

- [ ] **Step 3: Implement ViewModel APIs**

Add:

```swift
struct ResolvedSkillTag: Identifiable, Hashable {
    let displayTag: String
    let skill: Skill?

    var id: String { displayTag }
    var isRegistered: Bool { skill != nil }
    var level: String { skill?.difficulty ?? "미등록" }
    var detailText: String {
        if let skill {
            return "\(skill.name), \(level)"
        }
        return "미등록 스킬"
    }
}
```

Add `resetCurrentRow`, `completeProject`, `unlinkPattern`, and tag resolution methods in `ProjectWorkspaceViewModel`.

- [ ] **Step 4: Run tests to verify GREEN**

Run the same `xcodebuild test` command. Expected: `ProjectWorkspaceViewModelTests` passes.

---

### Task 2: Split Workspace Views

**Files:**
- Modify: `KnitGether/Views/MyKnitting/ProjectWorkspaceView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceHeaderView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceSummaryView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectPatternPanelView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectCounterPanelView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectRowGuidePanelView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectWorkTimePanelView.swift`
- Create: `KnitGether/Views/MyKnitting/Workspace/ProjectMemoPanelView.swift`

**Interfaces:**
- Consumes: ViewModel APIs from Task 1 and existing sheet state bindings in `ProjectWorkspaceView`.
- Produces: smaller SwiftUI components with action closures instead of direct repository access.

- [ ] **Step 1: Move pure presentation code**

Extract header, summary, work time, memo, pattern, counter, and row guide sections. Each extracted view receives only value data, bindings, and action closures.

- [ ] **Step 2: Keep sheet ownership in coordinator**

`ProjectWorkspaceView` continues to own `@State` for file importer, pattern picker, manual pattern sheet, row editor sheets, confirmations, and alert presentation.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds.

---

### Task 3: Restore User-Facing Workspace Affordances

**Files:**
- Modify: `KnitGether/Views/MyKnitting/ProjectWorkspaceView.swift`
- Modify: `KnitGether/Views/MyKnitting/Workspace/ProjectPatternPanelView.swift`
- Modify: `KnitGether/Views/MyKnitting/Workspace/ProjectCounterPanelView.swift`
- Modify: `KnitGether/Views/MyKnitting/Workspace/ProjectRowGuidePanelView.swift`

**Interfaces:**
- Consumes: `resetCurrentRow() async`, `completeProject() async`, `unlinkPattern() async`, `currentResolvedSkillTags`.
- Produces: UI actions for pattern unlink, row reset, target-completion prompt, skill chips, and clearer empty/manual PDF states.

- [ ] **Step 1: Add destructive confirmation states**

Add confirmations for row reset and pattern unlink in the coordinator.

- [ ] **Step 2: Add target completion prompt**

After incrementing or manually setting the row, if `currentRow >= targetRow` and project is not completed, show an alert offering to mark complete.

- [ ] **Step 3: Add skill tag chips**

Render current row tags and row list tags using `ResolvedSkillTag`. Registered tags use skill difficulty, unregistered tags show `미등록`.

- [ ] **Step 4: Build**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds.

---

### Task 4: Full Verification

**Files:**
- Verify only.

**Interfaces:**
- Consumes: all implementation from Tasks 1-3.
- Produces: verified result for handoff.

- [ ] **Step 1: Run iOS tests**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:KnitGetherTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: all `KnitGetherTests` pass.

- [ ] **Step 2: Run server tests only if server files changed**

If no server files changed in this UX pass, skip. If server files changed, run:

```bash
npm test
```

from `server/`. Expected: all server tests pass.

- [ ] **Step 3: Review changed files**

Run:

```bash
git status --short
git diff --stat
```

Expected: changed files are limited to the workspace UX plan and iOS workspace/ViewModel/test files, plus pre-existing dirty files from the row guide server slice.
