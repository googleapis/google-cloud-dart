## 0.6.0+1

- Updated `README.md` to reference `StructuredLogger` instead of
  `currentLogger` and specify W3C `traceparent` headers.
- Expanded doc comments on `createLoggingMiddleware` and
  `cloudLoggingMiddleware` to explain `Zone` variable injection and
  `StructuredLogger` correlation.

## 0.6.0

- Added the trace context to each request's `Zone` so that
  `package:google_cloud_logging` can correlate logs with
  the incoming request.
- **BREAKING:** Removed `TraceContextData`.
- **BREAKING:** Removed `currentLogger`.

## 0.5.0

- Initial release.
