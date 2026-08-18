---
name: google-cloud-location-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_location
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `Locations` can be tested by injecting the
  fake `FakeLocations`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_location/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_location/location.dart';
import 'package:google_cloud_location/testing.dart';

final fake = FakeLocations(
  getLocation: (request) async {
    // Assert request contents here if needed.
    return Location();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_location/location.dart';
import 'package:google_cloud_location/testing.dart';

final class MyFakeLocations extends FakeLocations {
  @override
  Future<Location> getLocation(
    GetLocationRequest request,
  ) async {
    // Assert request contents here if needed.
    return Location();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_location/location.dart';
import 'package:google_cloud_location/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(Locations service) async {
  // Application logic here.
  await service.getLocation(GetLocationRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeLocations(
      getLocation: (request) async {
          // Assert request contents here.
          return Location();
      },
    );
    // Instead of verifying that `functionUnderTest`, you should verify the
    // relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
