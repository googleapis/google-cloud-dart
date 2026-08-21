---
name: google-cloud-logging-v2-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_logging_v2
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `LoggingServiceV2` can be tested by injecting the
  fake `FakeLoggingServiceV2`.
- Code that uses `ConfigServiceV2` can be tested by injecting the
  fake `FakeConfigServiceV2`.
- Code that uses `MetricsServiceV2` can be tested by injecting the
  fake `FakeMetricsServiceV2`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_logging_v2/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:google_cloud_logging_v2/testing.dart';

final fake = FakeConfigServiceV2(
  createView: (request) async {
    // Assert request contents here if needed.
    return LogView();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:google_cloud_logging_v2/testing.dart';

final class MyFakeConfigServiceV2 extends FakeConfigServiceV2 {
  @override
  Future<LogView> createView(
    CreateViewRequest request,
  ) async {
    // Assert request contents here if needed.
    return LogView();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:google_cloud_logging_v2/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(ConfigServiceV2 service) async {
  // Application logic here.
  await service.createView(CreateViewRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeConfigServiceV2(
      createView: (request) async {
          // Assert request contents here.
          return LogView();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
