# Google Cloud Logging for Dart

[![pub package](https://img.shields.io/pub/v/google_cloud_logging.svg)](https://pub.dev/packages/google_cloud_logging)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_logging.svg)](https://pub.dev/packages/google_cloud_logging/publisher)

> NOTE: This is a **community-supported project**, meaning there is no official
> level of support. The code is not covered by any SLA or deprecation policy.
>
> Feel free to open [issues] for bugs and feature requests.

A lightweight logging package for creating formatted logs suitable for Google
Cloud Platform, specifically tailored for Google Cloud [structured logging].

## Usage

### Using the `StructuredLogger` directly

<?code-excerpt "example/structured_logger.dart (cloud-logger)"?>
```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';

const _logger = StructuredLogger();

void main() {
  _logger.info({'message': 'Processing item.', 'itemId': 'A-987'});
  try {
    throw Exception('Failed to connect to DB');
  } catch (error, stack) {
    _logger.error('Database connection failure - $error', stackTrace: stack);
  }
}
```

### Using `StructuredLogger` with `package:logging`

<?code-excerpt "example/cloud_logger.dart (cloud-logger)"?>
```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logging/logging.dart';

final _logger = Logger('my-service');

void main() {
  // Configure the standard logger with StructuredLogger.
  Logger.root.onRecord.listen(const StructuredLogger().handleLogRecord);
  Logger.root.level = Level.ALL;

  _logger.info('Processing item.', {'itemId': 'A-987'});
  try {
    throw Exception('Failed to connect to DB');
  } catch (error, stack) {
    _logger.severe('Database connection failure - $error', error, stack);
  }
}
```

[issues]: https://github.com/googleapis/google-cloud-dart/issues
[structured logging]: https://docs.cloud.google.com/logging/docs/structured-logging
