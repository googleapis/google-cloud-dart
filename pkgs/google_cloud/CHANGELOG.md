## 0.4.2-wip

### `http_serving.dart`

- REMOVED/BREAKING: `BadRequestException` and `badRequestMiddleware`
  are removed.
  - Replaced by `HttpResponseException` and `errorLoggingMiddleware`,
    respectively.
- Expanded `HttpResponseException` to support structured error reporting as
  per AIP-193.
  - Added `status` (`String?`) and `details` (`List<Map<String, Object?>>?`)
    fields.
  - Added `toJson()` method to serialize the error into a standard Google Cloud
    error payload.
  - Updated `toString()` to include `status` and `details` when non-null.
  - Added factory constructors for common HTTP 4XX and 5XX status codes:
    - `badRequest` (400)
    - `unauthorized` (401)
    - `forbidden` (403)
    - `notFound` (404)
    - `conflict` (409)
    - `tooManyRequests` (429)
    - `internalServerError` (500)
    - `notImplemented` (501)
    - `serviceUnavailable` (503)
    - `gatewayTimeout` (504)
  - Added default `status` values for factories that map 1:1 to gRPC status
    codes (e.g., `unauthorized` defaults to `'UNAUTHENTICATED'`).
- Updated `errorLoggingMiddleware` to leverage
  `HttpResponseException.toJson()` for JSON responses, returning a standard
  Google Cloud error payload.
- Updated plain text errors to use `HttpResponseException.toString()`.

## 0.4.1

- Update dependency `meta: ^1.17.0` to allow workspaces with stable Flutter.

## 0.4.0

### `constants.dart`

- Added `logSpanIdKey`, `logTraceKey`, and `logTraceSampledKey`.

### `general.dart`

- **BREAKING** `structuredLogEntry` removed `traceId` parameter. Use the *new*
  `payload` parameter with the `logTraceKey` constant as a key.
- Hardened structured log JSON serialization with automatic fallback mechanisms
  to safely handle native `toJson()` implementations and circular references
  without failing.

- Added `CloudLogger` (renamed from `RequestLogger`).
  - Added optional `payload` and `stackTrace` named parameters to
    `CloudLogger` functions.
  - `CloudLogger` is no longer abstract and has a default implementation that
    prints to stdout.

### `http_serving.dart`

- **BREAKING** Renamed `RequestLogger` to `CloudLogger` and moved it to
  `package:google_cloud/general.dart`.
- Refactored HTTP logging logic to handle `spanId` and `traceSampled`.

## 0.3.1

- Fix a bug where `projectIdFromGcloudConfig()` used the incorrect gcloud shell
  command on Windows.

## 0.3.0

### BREAKING CHANGES

- Split the library into two main entry points:
  - `package:google_cloud/general.dart` for general GCP features like project
    discovery, identity discovery, and core structured logging.
  - `package:google_cloud/http_serving.dart` for HTTP serving features like
    port discovery, shelf middleware, and signal handling.
  - `package:google_cloud/google_cloud.dart` remains as an umbrella library
    exporting both.
- Renamed `projectIdFromEnvironment()` to `projectIdFromEnvironmentVariables()`.
- Renamed `portEnvironmentKey` to `portEnvironmentVariable`.
- Renamed `listenPort()` to `listenPortFromEnvironment()`.
- `computeProjectId()`, `projectIdFromMetadataServer()`, and
  `serviceAccountEmailFromMetadataServer()` now leverage a unified process-wide
  metadata cache.
- **Breaking Change**: Local discovery strategies (environment variables,
  credentials files, and `gcloud` config) are no longer cached.
- **Breaking Change**: `projectIdFromMetadataServer()` and
  `serviceAccountEmailFromMetadataServer()` now throw
  `MetadataServerException` (which wraps `SocketException`, `TimeoutException`,
  or `ClientException`) when discovery fails.
- Constants are now exported via `package:google_cloud/constants.dart` and are
  no longer exported by `package:google_cloud/google_cloud.dart`.
- Require Dart 3.9.
- Require `package:http` `^1.1.0`.

### New Features

- Added `getMetadataValue()` (caching) and `fetchMetadataValue()` (non-caching)
  to `package:google_cloud/general.dart`.
- Added `projectIdFromCredentialsFile()` to automatically discover project ID
  from the credentials JSON file.
- Added `projectIdFromGcloudConfig()` to automatically discover project ID from
  gcloud CLI configuration.
- Added `serviceAccountEmailFromMetadataServer()` to discover the default
  service account email.
- Added `gceMetadataHost` and `gceMetadataUrl` to interact with the metadata
  server.
- `projectIdFromMetadataServer()` now respects the `GCE_METADATA_HOST`
  environment variable.
- Added `refresh` parameter to `computeProjectId()`,
  `projectIdFromMetadataServer()`, and `serviceAccountEmailFromMetadataServer()`
  to force re-discovery.
- Added `client` parameter to `computeProjectId()`,
  `projectIdFromMetadataServer()`, and `serviceAccountEmailFromMetadataServer()`
  to allow providing a custom `http.Client`.
- Added `structuredLogEntry()` for low-level structured log creation.

## 0.2.0

- First release replacing `package:gcp`.
