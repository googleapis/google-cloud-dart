---
name: google-cloud-ai-generativelanguage-v1beta-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_ai_generativelanguage_v1beta
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `CacheService` can be tested by injecting the
  fake `FakeCacheService`.
- Code that uses `DiscussService` can be tested by injecting the
  fake `FakeDiscussService`.
- Code that uses `FileService` can be tested by injecting the
  fake `FakeFileService`.
- Code that uses `GenerativeService` can be tested by injecting the
  fake `FakeGenerativeService`.
- Code that uses `ModelService` can be tested by injecting the
  fake `FakeModelService`.
- Code that uses `PermissionService` can be tested by injecting the
  fake `FakePermissionService`.
- Code that uses `PredictionService` can be tested by injecting the
  fake `FakePredictionService`.
- Code that uses `RetrieverService` can be tested by injecting the
  fake `FakeRetrieverService`.
- Code that uses `TextService` can be tested by injecting the
  fake `FakeTextService`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_ai_generativelanguage_v1beta/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/testing.dart';

final fake = FakeFileService(
  createFile: (request) async {
    // Assert request contents here if needed.
    return CreateFileResponse();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/testing.dart';

final class MyFakeFileService extends FakeFileService {
  @override
  Future<CreateFileResponse> createFile(
    CreateFileRequest request,
  ) async {
    // Assert request contents here if needed.
    return CreateFileResponse();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(FileService service) async {
  // Application logic here.
  await service.createFile(CreateFileRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeFileService(
      createFile: (request) async {
          // Assert request contents here.
          return CreateFileResponse();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
