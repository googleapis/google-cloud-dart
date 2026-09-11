---
name: google-cloud-tasks-v2-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_tasks_v2
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `CloudTasks` can be tested by injecting the
  fake `FakeCloudTasks`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_tasks_v2/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:google_cloud_tasks_v2/testing.dart';

final fake = FakeCloudTasks(
  getTask: (request) async {
    // Assert request contents here if needed.
    return Task();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:google_cloud_tasks_v2/testing.dart';

final class MyFakeCloudTasks extends FakeCloudTasks {
  @override
  Future<Task> getTask(
    GetTaskRequest request,
  ) async {
    // Assert request contents here if needed.
    return Task();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:google_cloud_tasks_v2/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(CloudTasks service) async {
  // Application logic here.
  await service.getTask(GetTaskRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeCloudTasks(
      getTask: (request) async {
          // Assert request contents here.
          return Task();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
