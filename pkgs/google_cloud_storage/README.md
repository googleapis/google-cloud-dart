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

<?code-excerpt "example/main.dart (main)"?>
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

By default, [idempotent Google Cloud Storage operations][] are retried if they
fail with a transient error (such as a network failure). Operations that aren't
idempotent are not retried, because repeating them could have unintended
effects.

The documentation for each `Storage` method indicates whether the operation is
idempotent. Some operations are only idempotent if a precondition, such as
`ifGenerationMatch`, is set.

You can pass `retry` to a method to control how that call is retried. A `retry`
argument is always used, even if the operation isn't idempotent. To disable
retries, pass `noRetry`. To retry the same errors as `defaultRetry` with
different limits or delays, create an `ExponentialRetry` with
`retryIf: isTransientError`.

For example:

<?code-excerpt "example/retry.dart (retry)"?>
```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';

void main() async {
  final storage = Storage();

  // This operation is only idempotent if `ifMetagenerationMatch` is provided,
  // so it is retried using `defaultRetry`.
  await storage.patchBucket(
    'my-bucket',
    BucketMetadataPatchBuilder()..labels = {'key': 'value'},
    ifMetagenerationMatch: BigInt.from(1),
  );

  // Retry this operation at most twice.
  await storage.bucketMetadata(
    'my-bucket',
    retry: const ExponentialRetry(retryIf: isTransientError, maxRetries: 2),
  );

  // Without `ifGenerationMatch`, this operation isn't idempotent, so it's only
  // retried because `retry` is passed. That's safe if nothing else writes
  // this object.
  await storage.uploadObjectFromString(
    'my-bucket',
    'status.txt',
    'OK',
    retry: defaultRetry,
  );

  storage.close();
}
```

## Feature Planning

<a href="https://github.com/orgs/googleapis/projects/37/views/1"
   target="_blank"
   rel="noopener noreferrer">Open Planning Board...</a>

[set up authentication]: https://docs.cloud.google.com/storage/docs/reference/libraries#authentication
[idempotent Google Cloud Storage operations]: https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency
