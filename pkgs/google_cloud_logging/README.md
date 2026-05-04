# Google Cloud Logging for Dart

A lightweight logging package for creating formatted logs suitable for Google
Cloud Platform, specifically tailored for Google Cloud structured logging.

## Features

* **Google Cloud Structured Logging:** Utilities to construct log entries that
  seamlessly map to Google Cloud's native structured logging schema on `stdout`.
* **CloudLogger:** An extensible base logging class with convenience methods for
  standard Google Cloud logging severities (`debug`, `info`, `notice`,
  `warning`, `error`, etc.).
* **Safe Sanitization:** Deep primitive checking to format complex object
  payloads, preventing cyclic referencing and providing graceful string
  fallback.

## Usage

### Structured Logging on stdout

```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';

void main() {
  // Create a simple structured log string
  final logString = createStructuredLog(
    'An informative event happened.',
    LogSeverity.info,
    payload: {'event_id': 123, 'status': 'success'},
  );

  // Print the formatted JSON directly to stdout
  print(logString);
}
```

### Using the CloudLogger

```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';

void main() {
  const logger = CloudLogger.defaultLogger();

  logger.info('Processing item.', payload: {'itemId': 'A-987'});

  try {
    throw Exception('Failed to connect to DB');
  } catch (e, stack) {
    logger.error('Database connection failure.', stackTrace: stack);
  }
}
```

## Running Tests

This package uses standard `package:test`:

```bash
dart test
```
