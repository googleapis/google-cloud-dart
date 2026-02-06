[![pub package](https://img.shields.io/pub/v/google_cloud_storage.svg)](https://pub.dev/packages/google_cloud_storage)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_storage.svg)](https://pub.dev/packages/google_cloud_storage/publisher)

A Dart client for Google Cloud Storage.

This package allows you to store and retrieve data on Google Cloud Storage.

## Using

The easiest way to use this library is via the `Storage` class.

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart';

void main() async {
  // Obtain an authenticated client.
  final client = await clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );

  final storage = Storage(client: client, projectId: 'my-project');

  // List buckets.
  await for (final bucket in storage.listBuckets()) {
    print(bucket.name);
  }

  storage.close();
}
```

## Idempotency



## Retries

By default, most [idempotent Google Cloud Storage operations][] are retried if
they fail with a transient error (such as a network failure).

The documentation for each `Storage` method indicates whether the operation is
idempotent.

You can control the retry behavior using the `retry` parameter on each method.

For example:

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart';

void main() async {
  final client = await clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );

  final storage = Storage(client: client, projectId: 'my-project');

  // This operation is only idempotent if `ifGenerationMatch` is provided.
  await storage.insertObject(
    'my-bucket',
    'my-object',
    ifGenerationMatch: 0,
    retry: ExponentialRetry(maxRetries: 2),
  );

  storage.close();
}
```

> [!NOTE]
> You will need to add [`googleapis_auth`](https://pub.dev/packages/googleapis_auth) to your dependencies to authenticate.

> [!NOTE]
> This package is currently in beta.

[idempotent Google Cloud Storage operations]: https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency
