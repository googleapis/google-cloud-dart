---
name: google-cloud-firestore-v1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_firestore_v1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `Firestore` can be tested by injecting the
  fake `FakeFirestore`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_firestore_v1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_firestore_v1/firestore.dart';
import 'package:google_cloud_firestore_v1/testing.dart';

final fake = FakeFirestore(
  getDocument: (request) async {
    // Assert request contents here if needed.
    return Document();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_firestore_v1/firestore.dart';
import 'package:google_cloud_firestore_v1/testing.dart';

final class MyFakeFirestore extends FakeFirestore {
  @override
  Future<Document> getDocument(
    GetDocumentRequest request,
  ) async {
    // Assert request contents here if needed.
    return Document();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_firestore_v1/firestore.dart';
import 'package:google_cloud_firestore_v1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(Firestore service) async {
  // Application logic here.
  await service.getDocument(GetDocumentRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeFirestore(
      getDocument: (request) async {
          // Assert request contents here.
          return Document();
      },
    );
    // Instead of verifying that `functionUnderTest`, you should verify the
    // relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
