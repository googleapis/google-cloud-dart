---
name: google-cloud-language-v2-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_language_v2
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `LanguageService` can be tested by injecting the
  fake `FakeLanguageService`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_language_v2/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_language_v2/language.dart';
import 'package:google_cloud_language_v2/testing.dart';

final fake = FakeLanguageService(
  analyzeSentiment: (request) async {
    // Assert request contents here if needed.
    return AnalyzeSentimentResponse();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_language_v2/language.dart';
import 'package:google_cloud_language_v2/testing.dart';

final class MyFakeLanguageService extends FakeLanguageService {
  @override
  Future<AnalyzeSentimentResponse> analyzeSentiment(
    AnalyzeSentimentRequest request,
  ) async {
    // Assert request contents here if needed.
    return AnalyzeSentimentResponse();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_language_v2/language.dart';
import 'package:google_cloud_language_v2/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(LanguageService service) async {
  // Application logic here.
  await service.analyzeSentiment(AnalyzeSentimentRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeLanguageService(
      analyzeSentiment: (request) async {
          // Assert request contents here.
          return AnalyzeSentimentResponse();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
