## 0.6.0-wip

- Added `StructuredLogHandler`, which allows integration with
  `package:logging`.
- Added the ability to add trace information to the output of
  `createStructuredLog`.
- **BREAKING:** Removed `payload` argument from `CloudLogger` methods.
- **BREAKING:** Removed `CloudLogger.printLogger`.
- **BREAKING:** Removed `createStructuredLogFromEntry`.
- **BREAKING:** Removed `formatStackTrace`.

## 0.5.0

- Added `CloudLogger`
- Added `createStructuredLog`.
- Added `createStructuredLogFromEntry`.
- Added export `LogSeverity` from `google_cloud_logging_type`.
- Added export `LogEntry` from `google_cloud_logging_v2`.
