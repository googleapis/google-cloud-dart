---
name: google-cloud-dns-v1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_dns_v1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `changes` can be tested by injecting the
  fake `Fakechanges`.
- Code that uses `dnsKeys` can be tested by injecting the
  fake `FakednsKeys`.
- Code that uses `managedZoneOperations` can be tested by injecting the
  fake `FakemanagedZoneOperations`.
- Code that uses `managedZones` can be tested by injecting the
  fake `FakemanagedZones`.
- Code that uses `policies` can be tested by injecting the
  fake `Fakepolicies`.
- Code that uses `projects` can be tested by injecting the
  fake `Fakeprojects`.
- Code that uses `resourceRecordSets` can be tested by injecting the
  fake `FakeresourceRecordSets`.
- Code that uses `responsePolicies` can be tested by injecting the
  fake `FakeresponsePolicies`.
- Code that uses `responsePolicyRules` can be tested by injecting the
  fake `FakeresponsePolicyRules`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_dns_v1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_dns_v1/dns.dart';
import 'package:google_cloud_dns_v1/testing.dart';

final fake = Fakepolicies(
  update: (request) async {
    // Assert request contents here if needed.
    return PoliciesUpdateResponse();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_dns_v1/dns.dart';
import 'package:google_cloud_dns_v1/testing.dart';

final class MyFakepolicies extends Fakepolicies {
  @override
  Future<PoliciesUpdateResponse> update(
    Policies_UpdateRequest request,
  ) async {
    // Assert request contents here if needed.
    return PoliciesUpdateResponse();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_dns_v1/dns.dart';
import 'package:google_cloud_dns_v1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(policies service) async {
  // Application logic here.
  await service.update(Policies_UpdateRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = Fakepolicies(
      update: (request) async {
          // Assert request contents here.
          return PoliciesUpdateResponse();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
