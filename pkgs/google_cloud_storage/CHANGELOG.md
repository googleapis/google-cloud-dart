## 0.7.0-wip

* **Breaking:** `ExponentialRetry` no longer has a built-in list of errors to
  retry. Pass a `retryIf` predicate, or use the new `ExponentialRetry.onCodes`
  constructor to retry errors with the given status codes.
* **Breaking:** A `retry` argument passed to a `Storage`, `Bucket` or
  `StorageObject` method is now always used, even if the operation isn't
  idempotent. Omit `retry` to retry only idempotent operations.
* **Breaking:** `RetryRunner.run` no longer takes an `isIdempotent` argument.
  A `RetryRunner` now only decides which errors are retried, and how long to
  wait between attempts; whoever chooses the runner decides whether an
  operation is safe to retry.
* `Storage.listBuckets` and `Storage.listObjects` now retry failed page
  requests, and take a `retry` argument.
* `Storage.deleteBucket` and `Bucket.delete` are now retried by default, even
  without `ifMetagenerationMatch`, because deleting a bucket is always
  idempotent.
* `Storage.deleteObjectAcl`, `Storage.patchObjectAcl` and
  `Storage.updateObjectAcl` are no longer retried by default when `generation`
  is set, because changing an ACL is never idempotent.
* `defaultRetry` now retries all HTTP 5xx responses, not just 500, 502, 503
  and 504, as the Cloud Storage retry strategy recommends.
* Add `isTransientError`, which returns whether an error is one that the Cloud
  Storage retry strategy considers transient.
* **Breaking:** Move retry classes (`RetryRunner`, `ExponentialRetry`) to
  `package:google_cloud_rpc/retry.dart` (no longer exported by
  `package:google_cloud_storage`).
* Move `ChecksumValidationException` to `package:google_cloud_rpc` (re-exported
  for backwards compatibility).
* Add `RetryRunner.isRetryable` and `RetryRunner.delays`.

## 0.6.4

* Send `gccl/<version>` in `x-goog-api-client` request header for API usage
  attribution.
* Require `google_cloud_rpc: ^0.6.0`.
* Add an `ifMetagenerationNotMatch` parameter to `Storage.patchBucket`,
  `Storage.uploadObject`, and `Storage.uploadObjectFromString`. If the
  precondition is not satisfied, a `NotModifiedException` is thrown.

## 0.6.3

* Add `prefix`, `delimiter`, and `includeTrailingDelimiter` parameters to
  `Storage.listObjects`.
* Add `Storage.rewriteObject`.
* Add `StorageObject.rewrite`.

## 0.6.2

* Add retries to `uploadObjectFromSink`.
* Add `Storage.moveObject`.
* Add `StorageObject.move`.
* Add new `Storage` methods for bucket ACLs:
  * `deleteBucketAcl`
  * `getBucketAcl`
  * `insertBucketAcl`
  * `listBucketAcl`
  * `patchBucketAcl`
  * `updateBucketAcl`
* Add new `Storage` methods for object ACLs:
  * `deleteObjectAcl`
  * `getObjectAcl`
  * `listObjectAcl`
  * `patchObjectAcl`
  * `updateObjectAcl`
* Add `Storage.makeObjectPublic`.
* Add `StorageObject.makePublic`.

## 0.6.1

* Add `Storage.insertObjectAcl`.

## 0.6.0

* **BREAKING:** Rename `Storage.insertObject` to `Storage.uploadObject`.
* Add `Storage.uploadObjectFromString`.
* Add `StorageObject.uploadFromString`.
* Require google_cloud: '>=0.3.0 <0.5.0'.

## 0.5.1

* Add support for using a `Future<Client>` in the `Storage` factory.

## 0.5.0

* Initial release for Dart 3. Support for basic Google Cloud Storage features:
  * Buckets (create, delete, get metadata, list, patch metadata)
  * Objects (create, delete, get metadata, list, patch metadata, read)

> [!NOTE]
> Versions 0.1.0 to 0.4.1-pre2 were released by Thomas Stephenson (thanks
> Thomas!) and supported Dart 1.
