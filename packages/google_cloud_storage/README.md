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

## Using Google Cloud Storage

All access to Google Cloud Storage is made through the `Storage` class.

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';

void main() async {
  // By default, the `Storage` class will use the currently configured project
  // and automatically attempt to authenticate using Application Default
  // Credentials.
  final storage = Storage();

  // Create a bucket.
  final bucket = await storage.createBucket(
    BucketMetadata(
      name: 'put-your-bucket-name-here',
      defaultObjectAcl: [
        ObjectAccessControl(entity: 'allUsers', role: 'READER'),
      ],
    ),
  );
  await storage.uploadObjectFromString(
    bucket.name!,
    'index.html',
    '<h1>Hello World!</h1>',
    metadata: ObjectMetadata(contentType: 'text/html'),
  );
  print(
    'Your website is available at:\n'
    'https://storage.googleapis.com/${bucket.name}/index.html',
  );
  storage.close();
}
```

> [!NOTE]
> You must [set up authentication][] before using this package outside of 
> Google Cloud.

## Retries

By default, most [idempotent Google Cloud Storage operations][] are retried if
they fail with a transient error (such as a network failure).

The documentation for each `Storage` method indicates whether the operation is
idempotent.

You can control the retry behavior using the `retry` parameter on each method.

For example:

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';

void main() async {
  final storage = Storage();

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
[set up authentication]: https://docs.cloud.google.com/storage/docs/reference/libraries#authentication
[idempotent Google Cloud Storage operations]: https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency
