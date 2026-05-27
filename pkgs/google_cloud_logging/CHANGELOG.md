## 0.6.0-wip

- Replaced `CloudLogger` with `StructuredLogger` which writes directly to
  stdout.
- Added `StructuredLogger.handleLogRecord` to integrate with `package:logging`.
- Added trace correlation support, parsing W3C `traceparent` headers and
  resolving trace and project context from the current `Zone`.
- Updated JSON sanitization to gracefully format cyclic references as
  `"[CIRCULAR]"` instead of throwing a `FormatException`.
- **BREAKING:** Removed the `CloudLogger` class and its `CloudLogger.printLogger` constructor.
- **BREAKING:** Removed `createStructuredLogFromEntry`.
- **BREAKING:** Removed public `formatStackTrace` function.

## 0.5.0

- Added `CloudLogger`
- Added `createStructuredLog`.
- Added `createStructuredLogFromEntry`.
- Added export `LogSeverity` from `google_cloud_logging_type`.
- Added export `LogEntry` from `google_cloud_logging_v2`.
