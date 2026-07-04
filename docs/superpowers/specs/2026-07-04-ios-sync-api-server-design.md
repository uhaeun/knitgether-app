# KnitGether iOS Sync API Server Design

Date: 2026-07-04
Status: Draft for user review

## Purpose

KnitGether needs a server-client structure for iOS app data synchronization and API access. The first server milestone should support account-scoped app data, pattern file metadata, project state, and file upload/download flows without forcing a full rewrite of the existing SwiftUI app.

The current app already separates data access behind repository protocols such as `ProjectRepository`, `PatternRepository`, `SkillRepository`, `LibraryRepository`, and `ProfileRepository`. The backend design should preserve that boundary by adding remote repository implementations rather than moving networking logic into views or view models.

## Decision

Use NestJS for the primary mobile API server.

Next.js is not the first choice for this milestone because the immediate goal is not a web app, landing page, or admin UI. Next.js can provide route handlers, but KnitGether's first backend needs a structured API service with clear modules, validation, authentication, file handling, and long-term maintainability. NestJS fits that server role better.

Future web surfaces can still be added later:

- Next.js admin or marketing web app
- NestJS API server shared by iOS and web
- PostgreSQL and object storage shared by both clients

## Architecture

```text
SwiftUI iOS App
  -> RemoteRepository implementations
  -> HTTP API client
  -> NestJS API server
  -> PostgreSQL
  -> S3-compatible object storage
```

The iOS app keeps its current local repository implementations during the transition. Remote repositories are added next to the local ones and wired through `AppRepositoryContainer` when the app runs in server-backed mode.

## Initial Scope

The first server-backed milestone should cover:

- Authentication session boundary for a single signed-in user
- User profile read/update
- Project list, project detail, create/update/delete
- Pattern document metadata list, detail, create/update/delete
- Project pattern copies and drawing metadata
- File upload/download URL flow for pattern PDFs and drawing data
- Timestamp-based sync for changed records

The first milestone should not include community features, sharing, comments, public pattern marketplace, paid content, or real-time collaboration.

Gauge data should be modeled after the basic sync path is working. It depends on product decisions around swatch history, wash-before/wash-after comparison, and links to pattern targets. The server should leave room for a later `gauge` module without blocking the first API milestone.

## Server Modules

### Auth

Responsibilities:

- Validate requests from authenticated users
- Attach the current `userId` to request context
- Prepare for Apple sign-in as the production auth provider

Initial implementation can use a simple development token or local auth adapter while the API shape is being built. Production auth should be swapped in behind the same guard boundary.

### Users

Responsibilities:

- Store app profile data
- Return the current user's profile
- Update display name and preference fields

Primary entity:

- `UserProfile`

### Projects

Responsibilities:

- Store user-owned knitting projects
- Save status, favorite state, memo, dates, row counter, work sessions, related skill IDs, and workspace preferences
- Soft-delete project records by setting `deletedAt`

Primary entities:

- `KnittingProject`
- `RowCounter`
- `WorkSession`

### Patterns

Responsibilities:

- Store user-owned pattern document metadata
- Store project-specific pattern copy metadata
- Preserve source pattern references through `sourcePatternDocumentId`
- Preserve drawing metadata independently from the PDF file

Primary entities:

- `PatternDocument`
- `ProjectPatternCopy`

### Files

Responsibilities:

- Issue upload URLs for pattern PDFs and drawing data
- Issue download URLs for files the current user owns
- Store object keys in database records, not public URLs

The mobile app should upload large files directly to object storage using signed URLs. The API server should own authorization and metadata, not stream every large PDF through application code.

### Sync

Responsibilities:

- Return records changed since a given timestamp
- Accept client changes with `updatedAt` and `deletedAt`
- Resolve simple conflicts predictably

Initial conflict rule:

- Server rejects stale updates when the incoming `updatedAt` is older than the stored record's `updatedAt`
- Client receives a conflict response and refreshes the affected record

This is deliberately simple for the MVP. Rich merge behavior can be added later only where users need it.

## API Shape

Use versioned REST endpoints under `/api/v1`.

Representative endpoints:

- `GET /api/v1/me`
- `PATCH /api/v1/me`
- `GET /api/v1/projects`
- `POST /api/v1/projects`
- `GET /api/v1/projects/:id`
- `PATCH /api/v1/projects/:id`
- `DELETE /api/v1/projects/:id`
- `GET /api/v1/patterns`
- `POST /api/v1/patterns`
- `GET /api/v1/patterns/:id`
- `PATCH /api/v1/patterns/:id`
- `DELETE /api/v1/patterns/:id`
- `POST /api/v1/files/upload-url`
- `POST /api/v1/files/download-url`
- `GET /api/v1/sync?since=<iso-date>`
- `POST /api/v1/sync`

Each response should use ISO-8601 timestamps and stable UUID strings so Swift `Codable` mapping stays straightforward.

## Data Ownership

Every user-owned row must include:

- `id`
- `ownerId`
- `createdAt`
- `updatedAt`
- `deletedAt`

API handlers must always scope reads and writes by the authenticated `ownerId`. The client must never be trusted to choose another owner.

## iOS Integration

Add remote repository implementations that conform to existing protocols:

- `RemoteProjectRepository: ProjectRepository`
- `RemotePatternRepository: PatternRepository`
- `RemoteProfileRepository: ProfileRepository`

Keep current local repositories available:

- Preview and sample data stay local
- Offline-first storage can be added later
- During migration, server-backed mode can be enabled behind configuration

Networking should live below repositories:

```text
ViewModel
  -> Repository protocol
  -> Remote repository
  -> API client
  -> URLSession
```

Views and view models should not know endpoint paths, token headers, or HTTP status codes.

## Error Handling

Server responses should use a consistent error format:

```json
{
  "code": "PROJECT_CONFLICT",
  "message": "Project was changed on another device.",
  "details": {}
}
```

Client repositories should translate HTTP failures into domain-level errors that view models can display or recover from.

Minimum error cases:

- `401` unauthenticated
- `403` access denied
- `404` record not found
- `409` sync conflict
- `413` file too large
- `422` validation failed
- `500` server error

## Testing Strategy

Server:

- Unit tests for services and conflict checks
- Controller tests for auth scoping and validation
- Integration tests against a test database for projects, patterns, files, and sync

iOS:

- API client tests with mocked URL responses
- Remote repository tests for request/response mapping
- Existing view model tests should continue to pass with mock repositories

The first implementation plan should start with contract-level tests for one vertical slice: authenticated project list fetch.

## Migration Plan

1. Scaffold the NestJS server under `server/`.
2. Add environment configuration, health check, validation, and global API prefix.
3. Add database schema and migrations for users, projects, pattern documents, project pattern copies, and file objects.
4. Implement auth guard with a development adapter.
5. Implement the projects vertical slice.
6. Add Swift API client and `RemoteProjectRepository`.
7. Wire server-backed mode through `AppRepositoryContainer`.
8. Repeat the pattern for profiles, patterns, files, and sync.

## Open Decisions

The following decisions are intentionally deferred until implementation planning:

- Exact production auth provider setup for Apple sign-in
- PostgreSQL ORM choice
- Object storage provider
- Whether offline-first local persistence is part of the first server milestone

For the current milestone, those choices must not change the public API boundary between the iOS app and the server.
