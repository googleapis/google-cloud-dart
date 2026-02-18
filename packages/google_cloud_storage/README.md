[![pub package](https://img.shields.io/pub/v/google_cloud_storage.svg)](https://pub.dev/packages/google_cloud_storage)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_storage.svg)](https://pub.dev/packages/google_cloud_storage/publisher)

A Dart client for Google Cloud Storage.

> [!NOTE]
> This package is currently experimental and published under the
> [labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order
> to solicit feedback.
>
> For packages in the labs.dart.dev publisher we generally plan to either
> graduate the package into a supported publisher (dart.dev, tools.dart.dev)
> after a period of feedback and iteration, or discontinue the package.
> These packages have a much higher expected rate of API and breaking changes.
>
> Your feedback is valuable and will help us evolve this package. For general
> feedback, suggestions, and comments, please file an issue in the
> [bug tracker](https://github.com/googleapis/google-cloud-dart/issues).

## Using

All access to Google Cloud Storage is made through the `Storage` class.

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart';

void main() async {
  // Obtain an authenticated client.
  final client = await clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );

  final storage = Storage(client: client, projectId: 'my-project');

  // Create a bucket.
  final bucket = await storage.createBucket(
    BucketMetadata(name: 'my-new-bucket'),
  );
  print('Created bucket: ${bucket.name}');

  storage.close();
}
```

> [!NOTE]
> You will need to add
> [`package:googleapis_auth`](https://pub.dev/packages/googleapis_auth)
> to your dependencies to authenticate.

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

  // This operation is only idempotent if `ifMetagenerationMatch` is provided.
  await storage.patchBucket(
    'my-bucket',
    BucketMetadataPatchBuilder()..labels = {'key': 'value'},
    ifMetagenerationMatch: 1,
    retry: ExponentialRetry(maxRetries: 2),
  );

  storage.close();
}
```

[idempotent Google Cloud Storage operations]: https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency
