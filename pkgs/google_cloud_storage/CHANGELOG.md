## 0.7.0-wip

* **Breaking:** A `retry` argument passed to a `Storage`, `Bucket` or
  `StorageObject` method is now always used, even if the operation isn't
  idempotent, as in the Python client library. Previously, it was ignored for
  operations that weren't idempotent. Omit `retry` to only retry idempotent
  operations.
* **Breaking:** `RetryRunner.run` no longer takes an `isIdempotent` argument.
  A `RetryRunner` now only decides which errors are retried, and how long to
  wait between attempts; whoever chooses the runner decides whether an
  operation is safe to retry.
* Add a `retry` parameter to the `Storage` constructor. It is used for
  idempotent operations that are called without a `retry` argument, and
  defaults to `defaultRetry`.
* `Storage.listBuckets` and `Storage.listObjects` now retry failed page
  requests, and take a `retry` argument.
* Add `ExponentialRetry.retryIf` to choose which errors are retried, with the
  `isTransientError` (the default) and `hasStatusCode` predicates.
* Add `noRetry` to disable retries.
* `defaultRetry` is now defined by this package instead of
  `package:google_cloud_rpc`. Its value is unchanged.
* Move retry classes (`RetryRunner`, `ExponentialRetry`) and
  `ChecksumValidationException` to `package:google_cloud_rpc` (re-exported for
  backwards compatibility).
* Add a `jitter` parameter to `ExponentialRetry` that randomizes the delay
  between retries.
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
