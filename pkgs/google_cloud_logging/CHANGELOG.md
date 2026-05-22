## 0.6.0-wip

- Added `StructuredLogHandler`, which allows integration with
  `package:logging`.
- **BREAKING:** Removed `payload` argument from `CloudLogger` methods.
- **BREAKING:** Removed `CloudLogger.printLogger`.
- **BREAKING:** Removed `createStructuredLogFromEntry`.

## 0.5.0

- Added `CloudLogger`
- Added `createStructuredLog`.
- Added `createStructuredLogFromEntry`.
- Added export `LogSeverity` from `google_cloud_logging_type`.
- Added export `LogEntry` from `google_cloud_logging_v2`.
