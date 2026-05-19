# Google Cloud Logging for Dart

[![pub package](https://img.shields.io/pub/v/google_cloud_logging.svg)](https://pub.dev/packages/google_cloud_logging)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_logging.svg)](https://pub.dev/packages/google_cloud_logging/publisher)

> NOTE: This is a **community-supported project**, meaning there is no official
> level of support. The code is not covered by any SLA or deprecation policy.
>
> Feel free to open [issues] for bugs and feature requests.

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

<?code-excerpt "example/structured_stdout.dart (structured-stdout)"?>
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

<?code-excerpt "example/cloud_logger.dart (cloud-logger)"?>
```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';

const _logger = CloudLogger.printLogger();

void main() {
  _logger.info('Processing item.', payload: {'itemId': 'A-987'});
  try {
    throw Exception('Failed to connect to DB');
  } catch (error, stack) {
    _logger.error('Database connection failure - $error', stackTrace: stack);
  }
}
```

### Integrating with `package:logging`

`CloudLogger` can be used as a global handler for the standard [`package:logging`](https://pub.dev/packages/logging) package.

This allows you to output structured logs for Google Cloud automatically without changing any existing logging code in your application or its dependencies.

<?code-excerpt "example/logging.dart"?>
```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logging/logging.dart';

void main() {
  const cloudLogger = CloudLogger.structuredLogger();
  Logger.root.onRecord.listen(cloudLogger.handleLog);
  Logger.root.level = Level.ALL;

  Logger('MyClassName').fine('Starting file copy.');
}
```

[issues]: https://github.com/googleapis/google-cloud-dart/issues
