---
name: google-cloud-secretmanager-v1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_secretmanager_v1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `SecretManagerService` can be tested by injecting the
  fake `FakeSecretManagerService`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_secretmanager_v1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:google_cloud_secretmanager_v1/testing.dart';

final fake = FakeSecretManagerService(
  enableManagedRotation: (request) async {
    // Assert request contents here if needed.
    return SecretVersion();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:google_cloud_secretmanager_v1/testing.dart';

final class MyFakeSecretManagerService extends FakeSecretManagerService {
  @override
  Future<SecretVersion> enableManagedRotation(
    EnableManagedRotationRequest request,
  ) async {
    // Assert request contents here if needed.
    return SecretVersion();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:google_cloud_secretmanager_v1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(SecretManagerService service) async {
  // Application logic here.
  await service.enableManagedRotation(EnableManagedRotationRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeSecretManagerService(
      enableManagedRotation: (request) async {
          // Assert request contents here.
          return SecretVersion();
      },
    );
    // Instead of verifying that `functionUnderTest`, you should verify the
    // relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
