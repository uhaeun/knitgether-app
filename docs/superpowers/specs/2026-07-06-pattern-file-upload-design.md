# KnitGether Pattern File Upload Design

## Context

KnitGether now has a server-backed project slice:

- NestJS API server under `server/`
- Prisma/Postgres persistence
- development bearer-token auth
- project list/detail/create/update/delete APIs
- Swift `APIClient`
- Swift `RemoteProjectRepository`
- environment-driven remote project mode in `AppRepositoryContainer`

The next gap is the pattern library. The iOS app already has `PatternRepository`, `PatternDocument`, `ProjectPatternCopy`, `LocalPatternRepository`, and `LocalPatternFileStore`. In remote mode, only projects are server-backed today. Pattern documents and PDF files remain local, so a remote project can reference pattern data that only exists on one device.

## Goal

Implement the first pattern file slice so the iOS app can upload PDF patterns to the server, list pattern documents, download PDF files back to the device, soft-delete patterns, and attach server-backed pattern metadata to projects.

This milestone should keep the current local repository behavior and only expand the remote path.

## Scope

Included:

- Prisma models and migration for pattern documents and stored files
- server-side local file storage rooted at `FILE_STORAGE_ROOT`
- `GET /api/v1/patterns`
- `POST /api/v1/patterns` with `multipart/form-data` PDF upload
- `GET /api/v1/patterns/:id`
- `PATCH /api/v1/patterns/:id`
- `DELETE /api/v1/patterns/:id`
- `GET /api/v1/patterns/:id/file`
- Swift `RemotePatternRepository`
- Swift `APIClient` support for multipart upload and binary download
- remote mode wiring in `AppRepositoryContainer` for pattern repository
- tests for server route behavior and Swift request/cache behavior

The pattern payload includes:

- pattern identity
- title
- designer
- file name
- page count, when supplied by the client or known later
- notes
- stored file metadata

Excluded:

- S3, MinIO, or signed upload/download URLs
- drawing data upload/download
- project-specific pattern copy API endpoints
- PDF text extraction or page counting on the server
- production auth
- offline queueing
- sync conflict resolution
- server deployment

## Architecture

The server adds a `patterns` module as the owner of pattern HTTP behavior. `PatternsController` exposes REST endpoints and delegates business rules to `PatternsService`. `PatternsService` owns owner scoping, metadata persistence, file association, response mapping, and soft deletion.

The server also adds a small file storage boundary, for example `LocalFileStorageService`, under a `files` or `storage` module. This service stores uploaded PDFs under `FILE_STORAGE_ROOT`, returns opaque relative storage keys, opens read streams for downloads, and deletes files when a pattern is soft-deleted. Keeping this boundary explicit makes a later S3/MinIO replacement possible without changing controller contracts.

The iOS app keeps using the existing `PatternRepository` protocol. `LocalPatternRepository` remains unchanged. `RemotePatternRepository` implements the protocol for the remote path by uploading selected PDFs, decoding pattern metadata, downloading PDFs into `LocalPatternFileStore`, and returning local cache URLs to existing PDF views.

The API remains versioned under `/api/v1`.

## Server API

### `GET /api/v1/patterns`

Returns active pattern documents owned by the authenticated user, sorted newest first. Soft-deleted patterns and patterns owned by another user are not returned.

### `POST /api/v1/patterns`

Creates a pattern document and uploads its PDF file in one request. The request uses `multipart/form-data`:

- `file`: required PDF file
- `id`: optional UUID provided by the client
- `title`: optional title; defaults to the uploaded file name without extension
- `designer`: optional string
- `pageCount`: optional integer
- `notes`: optional string

The server validates that the uploaded file is a PDF by MIME type and file extension. It stores the file under the authenticated owner scope and creates a `PatternDocument` row plus file metadata in a transaction.

### `GET /api/v1/patterns/:id`

Returns one active pattern document for the authenticated owner. If the pattern does not exist, belongs to another owner, or is soft-deleted, return `404 PATTERN_NOT_FOUND`.

### `PATCH /api/v1/patterns/:id`

Updates mutable pattern metadata for an active owner-scoped pattern:

- `title`
- `designer`
- `pageCount`
- `notes`

This endpoint does not replace the PDF file. File replacement is reserved for a later milestone.

### `DELETE /api/v1/patterns/:id`

Soft-deletes the owner-scoped pattern and removes its stored PDF from local file storage. Repeated deletion of a missing or already-deleted pattern returns `404 PATTERN_NOT_FOUND`.

### `GET /api/v1/patterns/:id/file`

Downloads the PDF for an active owner-scoped pattern. The response uses `application/pdf` and a `Content-Disposition` attachment file name derived from the stored file metadata. If the file record is missing or the disk file no longer exists, return `404 PATTERN_FILE_NOT_FOUND`.

## Data Model

`PatternDocument`:

- `id`
- `ownerId`
- `title`
- `designer`
- `fileName`
- `pageCount`
- `notes`
- `storedFileId`
- `createdAt`
- `updatedAt`
- `deletedAt`

`StoredFile`:

- `id`
- `ownerId`
- `kind`, initially `patternPdf`
- `originalFileName`
- `contentType`
- `byteSize`
- `storageKey`
- `createdAt`
- `updatedAt`
- `deletedAt`

The server never returns `storageKey` to the client. The client gets pattern metadata and downloads files through authorized API routes.

## Storage

`FILE_STORAGE_ROOT` defaults to `server/storage` for local development. The server creates directories as needed and stores files under owner-scoped paths such as:

`patterns/<ownerId>/<patternId>/<storedFileId>.pdf`

The API treats storage keys as internal implementation details. The storage service must prevent path traversal by constructing storage paths from trusted IDs, not from user-submitted relative paths.

In development, `server/storage` should be ignored by git. Docker remains Postgres-only for this milestone; the API process writes files to the host filesystem.

## iOS Integration

`AppRepositoryContainer.makeDefault` should switch both project and pattern repositories to remote implementations when `KNITGETHER_API_BASE_URL` is configured. If the API base URL is missing, both repositories remain local.

`RemotePatternRepository.createPattern(fromFileAt:)`:

1. reads the selected PDF using security-scoped access
2. sends `POST /patterns` as multipart form data
3. decodes the returned `PatternDocument`
4. downloads the file through `GET /patterns/:id/file`
5. stores it in `LocalPatternFileStore` using the returned pattern id
6. returns a `PatternDocument` whose `localFilePath` points at the local cache

`RemotePatternRepository.fetchPatterns()`:

1. fetches metadata from `GET /patterns`
2. returns documents without forcing all PDFs to download
3. preserves any existing local cache path when the file is already cached

`RemotePatternRepository.fileURL(for:)`:

- returns the cached local PDF URL when present
- does not perform network work because the protocol method is synchronous

`RemotePatternRepository.fetchPattern(id:)`:

- fetches one metadata record
- downloads and caches the PDF on demand if the local cache is missing

`RemotePatternRepository.deletePattern(id:)`:

- sends `DELETE /patterns/:id`
- removes any matching local cached PDF

`RemotePatternRepository.importPattern(_:forProjectId:)`:

- creates a `ProjectPatternCopy` snapshot from the remote pattern metadata
- downloads and copies the PDF into the project-specific local cache when available
- leaves the source `PatternDocument` id in `sourcePatternDocumentId`

`RemotePatternRepository.createProjectPatternCopy(fromFileAt:forProjectId:)` remains local for this milestone. It creates a project-only copy from a selected file and relies on the project save API to persist the snapshot once project pattern copies are added to the server response model in a later slice.

## Project Pattern Copies

The project CRUD API currently returns `patternCopy: null` and does not persist `ProjectPatternCopy`. This pattern upload milestone does not change that contract. It only ensures that pattern library documents and their PDF files can live on the server.

When a user attaches a library pattern to a project, iOS can still create a `ProjectPatternCopy` snapshot locally. Persisting that copy on the server requires a separate project-pattern-copy slice because it changes the project response and save payload contracts.

## Error Handling

Server responses use the existing error envelope shape:

- `401 UNAUTHENTICATED` for missing or invalid token
- `400 VALIDATION_FAILED` for invalid body, invalid UUID, missing file, non-PDF file, or oversized upload
- `404 PATTERN_NOT_FOUND` for inaccessible patterns
- `404 PATTERN_FILE_NOT_FOUND` for missing PDF files on download

Swift keeps mapping non-2xx API responses to `APIError.requestFailed`. View models already convert repository failures into user-facing Korean error messages.

The server should set a conservative upload size limit for this milestone, for example 50 MB. The exact value is configuration-driven through `PATTERN_UPLOAD_MAX_BYTES`.

## Testing

Server:

- unauthenticated pattern requests are rejected
- `POST /patterns` rejects missing or non-PDF uploads
- `POST /patterns` stores PDF file metadata and returns a Swift-compatible pattern response
- `GET /patterns` returns only active patterns owned by the current user
- `GET /patterns/:id` returns an owner-scoped pattern
- `PATCH /patterns/:id` updates owner-scoped metadata
- `GET /patterns/:id/file` downloads the owner-scoped PDF with `application/pdf`
- `DELETE /patterns/:id` soft-deletes metadata and removes the disk file

iOS:

- `RemotePatternRepository.fetchPatterns()` requests `GET /patterns` and decodes metadata
- `createPattern(fromFileAt:)` sends multipart PDF upload
- `createPattern(fromFileAt:)` downloads and caches the returned PDF
- `fetchPattern(id:)` downloads and caches the file when needed
- `deletePattern(id:)` sends `DELETE /patterns/:id` and clears local cache
- `AppRepositoryContainer.makeDefault` uses remote pattern repository when the API base URL is configured

Verification:

- `npm test` in `server`
- `npm run build` in `server`
- `xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination <simulator> -only-testing:KnitGetherTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO`

## Follow-Up Milestones

After this slice, the next meaningful server-client milestones are:

1. Project pattern copy persistence in project save/response APIs.
2. Remote drawing data upload/download for project pattern copies.
3. Gauge calculator model redesign with before/after wash comparison and pattern target linkage.
4. Real auth.
5. Offline-first sync and conflict handling.
