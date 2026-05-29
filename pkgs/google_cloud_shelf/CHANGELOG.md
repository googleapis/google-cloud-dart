## 0.6.0-wip

- Added the trace context to each request's `Zone` so that
  `package:google_cloud_logging` can correlate logs with
  the incoming request.
- **BREAKING:** Removed `TraceContextData`.
- **BREAKING:** Removed `currentLogger`.

## 0.5.0

- Initial release.
