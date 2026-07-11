# KnitGether Project CRUD Design

## Context

KnitGether already has the first server-client slice:

- NestJS API server under `server/`
- Prisma/Postgres persistence
- development bearer-token auth
- `GET /api/v1/projects`
- Swift `APIClient`
- Swift `RemoteProjectRepository.fetchProjects()`
- environment-driven remote project mode in `AppRepositoryContainer`

The next milestone is to make the server-backed project repository usable by the existing iOS project screens. Today the iOS app calls `ProjectRepository.saveProject(_:)` and `ProjectRepository.deleteProject(id:)` from multiple workflows, but the remote implementation still throws unsupported-operation errors.

## Goal

Implement the first project write slice so the iOS app can create, edit, soft-delete, and reload projects through the API when `KNITGETHER_API_BASE_URL` is configured.

This milestone should preserve the current local repository behavior and only expand the remote path.

## Scope

Included:

- `GET /api/v1/projects/:id`
- `POST /api/v1/projects`
- `PATCH /api/v1/projects/:id`
- `DELETE /api/v1/projects/:id`
- Swift `RemoteProjectRepository.saveProject(_:)`
- Swift `RemoteProjectRepository.deleteProject(id:)`
- request validation and owner scoping on every server write
- tests for server route behavior and Swift request behavior

The project payload includes:

- project identity
- name, status, favorite flag, memo, start date, last worked date
- workspace display mode and sheet position
- related skill ids
- row counter state
- work session records

Excluded:

- pattern PDF upload/download
- remote pattern library CRUD
- project pattern copy persistence beyond returning `patternCopy: null`
- production auth
- offline queueing
- sync conflict resolution
- server deployment

## Architecture

The server keeps a `projects` module as the owner of project HTTP behavior. `ProjectsController` exposes REST endpoints and delegates business rules to `ProjectsService`. `ProjectsService` owns owner scoping, persistence, mapping Prisma records to the Swift-compatible response shape, and soft deletion.

The iOS app keeps using the existing `ProjectRepository` protocol. `LocalProjectRepository` remains unchanged. `RemoteProjectRepository` becomes a full remote implementation for the protocol's current methods by serializing `KnittingProject` into the API request body and decoding the server response into the existing app model.

The API remains versioned under `/api/v1`.

## Server API

### `GET /api/v1/projects/:id`

Returns one active project for the authenticated owner. If the project does not exist, belongs to another owner, or is soft-deleted, return `404 PROJECT_NOT_FOUND`.

### `POST /api/v1/projects`

Creates a project owned by the authenticated user. The client may provide its UUID so local and remote identity can remain stable. If the ID already exists for the same owner, the server treats the request as an upsert-like save and updates that project instead of creating a duplicate.

The server ensures a user profile exists for the development-auth owner before writing the project.

### `PATCH /api/v1/projects/:id`

Updates an active project owned by the authenticated user. If the ID is missing, owned by someone else, or soft-deleted, return `404 PROJECT_NOT_FOUND`.

### `DELETE /api/v1/projects/:id`

Soft-deletes the project and its child row counter/work sessions for the authenticated owner. Repeated deletion of a missing or already-deleted project returns `404 PROJECT_NOT_FOUND`, not success, because the app should know when its local view is stale.

## Request Model

The Swift client sends a project save payload derived from `KnittingProject`:

- `id`
- `name`
- `status`
- `isFavorite`
- `memo`
- `startDate`
- `lastWorkedAt`
- `workspaceDisplayMode`
- `workspaceSheetPosition`
- `relatedSkillIds`
- `rowCounter`
- `workSessions`

The server ignores client-supplied `ownerId`, `createdAt`, `updatedAt`, `deletedAt`, and `syncStatus` for authorization and system state. It derives `ownerId` from auth and returns server-generated timestamps.

`patternCopy` is intentionally not accepted in this milestone. The response remains `patternCopy: null` until the pattern/file module is implemented.

## Data Flow

Create project:

1. iOS creates a `KnittingProject` from `ProjectFormData`.
2. `RemoteProjectRepository.saveProject(_:)` sends `POST /projects`.
3. Server validates the body and creates the `Project` and required `RowCounter`.
4. Server returns a full `ProjectResponseDto`.
5. The app reloads the list through `fetchProjects()`, matching the current local repository workflow.

Update project, memo, row, workspace position, and work sessions:

1. iOS mutates the `KnittingProject` in memory.
2. `RemoteProjectRepository.saveProject(_:)` sends `PATCH /projects/:id` after the project exists remotely.
3. Server replaces the basic project fields, row counter state, and submitted work session set for that project.
4. Server returns the full project response.

Delete project:

1. iOS calls `RemoteProjectRepository.deleteProject(id:)`.
2. Server soft-deletes the project and child records.
3. The app reloads project list and the deleted project no longer appears.

## Error Handling

Server responses use the existing error envelope shape:

- `401 UNAUTHENTICATED` for missing or invalid token
- `400 VALIDATION_FAILED` for invalid body or UUID/date values
- `404 PROJECT_NOT_FOUND` for inaccessible projects
- `409 PROJECT_ALREADY_DELETED` is reserved for future conflict-aware sync and not used in this milestone

Swift keeps mapping non-2xx API responses to `APIError.requestFailed`. View models already convert repository failures into user-facing Korean error messages.

## Testing

Server:

- unauthenticated requests are rejected
- `GET /projects/:id` returns an owner-scoped project
- `GET /projects/:id` returns 404 for missing or non-owned projects
- `POST /projects` validates and creates project plus row counter
- `PATCH /projects/:id` updates project, row counter, and work sessions
- `DELETE /projects/:id` soft-deletes the owner-scoped project

iOS:

- `saveProject(_:)` sends `POST /projects` for a new remote project
- `saveProject(_:)` sends `PATCH /projects/:id` for a synced remote project
- request body includes project fields, row counter, and work sessions
- `deleteProject(id:)` sends `DELETE /projects/:id`
- server response decoding continues to produce `KnittingProject`

Verification:

- `npm test` in `server`
- `npm run build` in `server`
- `xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination <simulator> -only-testing:KnitGetherTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO`

## Follow-Up Milestones

After this slice, the next meaningful server-client milestones are:

1. Pattern document metadata API and remote pattern repository.
2. Pattern PDF and drawing file upload/download.
3. Gauge calculator model redesign with before/after wash comparison and pattern target linkage.
4. Real auth.
5. Offline-first sync and conflict handling.
