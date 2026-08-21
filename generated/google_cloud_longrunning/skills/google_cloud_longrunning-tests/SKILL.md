---
name: google-cloud-longrunning-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_longrunning
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `Operations` can be tested by injecting the
  fake `FakeOperations`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_longrunning/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_longrunning/longrunning.dart';
import 'package:google_cloud_longrunning/testing.dart';

final fake = FakeOperations(
  deleteOperation: (request) async {
    // Assert request contents here if needed.
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_longrunning/longrunning.dart';
import 'package:google_cloud_longrunning/testing.dart';

final class MyFakeOperations extends FakeOperations {
  @override
  Future<void> deleteOperation(
    DeleteOperationRequest request,
  ) async {
    // Assert request contents here if needed.
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_longrunning/longrunning.dart';
import 'package:google_cloud_longrunning/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(Operations service) async {
  // Application logic here.
  await service.deleteOperation(DeleteOperationRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeOperations(
      deleteOperation: (request) async {
          // Assert request contents here.
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
