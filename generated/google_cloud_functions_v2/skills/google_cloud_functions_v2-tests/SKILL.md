---
name: google-cloud-functions-v2-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_functions_v2
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `FunctionService` can be tested by injecting the
  fake `FakeFunctionService`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_functions_v2/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_functions_v2/cloudfunctions.dart';
import 'package:google_cloud_functions_v2/testing.dart';

final fake = FakeFunctionService(
  getFunction: (request) async {
    // Assert request contents here if needed.
    return Function$();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_functions_v2/cloudfunctions.dart';
import 'package:google_cloud_functions_v2/testing.dart';

final class MyFakeFunctionService extends FakeFunctionService {
  @override
  Future<Function$> getFunction(
    GetFunctionRequest request,
  ) async {
    // Assert request contents here if needed.
    return Function$();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_functions_v2/cloudfunctions.dart';
import 'package:google_cloud_functions_v2/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(FunctionService service) async {
  // Application logic here.
  await service.getFunction(GetFunctionRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeFunctionService(
      getFunction: (request) async {
          // Assert request contents here.
          return Function$();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
