# Workspace UX Restoration Design

## Context

The current server-client branch has restored the project workspace enough to compile and sync project, pattern copy, drawing, row counter, and row guide data. However, the workspace still feels different from the earlier app because several user-facing affordances from the old CoreData workspace are either missing, too flat, or hidden inside one large view file.

This design covers the next incremental step: restore the old workspace feel and missing low-risk interactions without expanding the server domain model beyond what already exists.

## Goals

- Make the project detail/workspace screen feel like a complete work surface again.
- Keep the three workspace modes visible: pattern only, pattern plus counter, counter only.
- Improve the pattern area so users can clearly attach, replace, view, draw on, manually name, or unlink a pattern.
- Improve the row counter so users can reset, edit, track progress, and handle target completion.
- Improve row guide mode so current-row instructions, skill tags, and instruction management are easier to scan.
- Reduce `ProjectWorkspaceView.swift` size by extracting focused SwiftUI components.
- Keep all changes compatible with the current remote repository and API shape.

## Non-Goals

- Do not add tool inventory/project tool linking in this step.
- Do not add persisted gauge records or project-linked gauge records in this step.
- Do not add project target date, end date, or D-day fields in this step.
- Do not redesign the full app shell or project list.

These non-goals need server schema, API, repository, and iOS model work, so they should be handled in the next server-backed feature slice.

## UX Design

The workspace should be structured as a vertical work surface:

1. Header: project name, status, favorite state, latest work metadata.
2. Project summary: start date, last worked date, total time, current display mode, pattern status, counter status.
3. Work timer: active session, total time, explicit finish/pause-style controls where feasible with the current data model.
4. Workspace mode picker.
5. Pattern panel:
   - Shows linked pattern title and file state.
   - Shows PDF preview when a file exists.
   - Keeps viewer/drawing mode.
   - Offers PDF direct add/replace, library import, manual input, unlink, and large view.
6. Counter panel:
   - Keeps simple and row guide modes.
   - Shows current row, target row, progress, section name, memo.
   - Adds reset action with confirmation.
   - When target row is reached, offers to mark the project complete.
7. Row guide details:
   - Shows current row instruction prominently.
   - Shows current row skill tags as chips.
   - Flags unregistered tags.
   - Keeps add, bulk add, renumber, edit, and delete.
8. Project memo and related skills remain visible after the active work controls.

## Architecture

Refactor the workspace into small local components under `KnitGether/Views/MyKnitting/Workspace/`.

Suggested components:

- `ProjectWorkspaceHeaderView`
- `ProjectWorkspaceSummaryView`
- `ProjectPatternPanelView`
- `ProjectCounterPanelView`
- `ProjectRowGuidePanelView`
- `ProjectRowInstructionRowView`
- `ProjectWorkTimePanelView`
- `ProjectMemoPanelView`
- `SkillTagChipView`

`ProjectWorkspaceView` remains the coordinator for sheets, alerts, and navigation. The view model remains the single owner of mutations and persistence.

## Data Flow

- `ProjectWorkspaceViewModel` continues to expose the current project, row counter, current row, drawing data, related skills, and available patterns.
- New view model methods should stay small and project-based:
  - reset current row to 0
  - update project status to complete
  - unlink pattern copy
  - expose resolved skill tags for row instructions
- The remote save path remains `ProjectRepository.saveProject`.
- Pattern file and drawing operations remain in `PatternRepository`.

## Error Handling

- Failed saves keep the current visible error alert pattern.
- Destructive actions require confirmation:
  - reset row
  - unlink pattern
  - clear drawing
  - delete row instruction
- If a pattern has no PDF file, the UI should explain that the manual pattern is still connected but cannot be previewed as a PDF.
- If a skill tag is not registered, the UI should show it as an unregistered chip instead of failing.

## Testing

- Run iOS build after refactor.
- Run iOS tests to ensure repository and decoding behavior are not broken.
- Run server tests only if DTO or API shapes are touched. This step should avoid server changes.
- Manually inspect the workspace in the simulator for:
  - three display modes
  - pattern add/replace/unlink/manual states
  - counter reset and target completion
  - row guide current instruction and tag chips

## Follow-Up Slice

After this UX restoration is stable, add a server-backed feature slice for:

- project-linked tools
- persisted gauge records
- project-linked gauge records
- target date, end date, and D-day summary
