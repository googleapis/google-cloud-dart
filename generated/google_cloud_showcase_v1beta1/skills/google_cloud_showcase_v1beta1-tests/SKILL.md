---
name: google-cloud-showcase-v1beta1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_showcase_v1beta1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `Compliance` can be tested by injecting the
  fake `FakeCompliance`.
- Code that uses `Echo` can be tested by injecting the
  fake `FakeEcho`.
- Code that uses `Identity` can be tested by injecting the
  fake `FakeIdentity`.
- Code that uses `Messaging` can be tested by injecting the
  fake `FakeMessaging`.
- Code that uses `ResumableUploadService` can be tested by injecting the
  fake `FakeResumableUploadService`.
- Code that uses `SequenceService` can be tested by injecting the
  fake `FakeSequenceService`.
- Code that uses `Testing` can be tested by injecting the
  fake `FakeTesting`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_showcase_v1beta1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:google_cloud_showcase_v1beta1/testing.dart';

final fake = FakeSequenceService(
  createSequence: (request) async {
    // Assert request contents here if needed.
    return Sequence();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:google_cloud_showcase_v1beta1/testing.dart';

final class MyFakeSequenceService extends FakeSequenceService {
  @override
  Future<Sequence> createSequence(
    CreateSequenceRequest request,
  ) async {
    // Assert request contents here if needed.
    return Sequence();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:google_cloud_showcase_v1beta1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(SequenceService service) async {
  // Application logic here.
  await service.createSequence(CreateSequenceRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeSequenceService(
      createSequence: (request) async {
          // Assert request contents here.
          return Sequence();
      },
    );
    // Instead of verifying that `functionUnderTest`, you should verify the
    // relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
