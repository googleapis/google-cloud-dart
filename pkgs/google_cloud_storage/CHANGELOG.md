## 0.7.0-wip

* **Breaking:** `ExponentialRetry` no longer has a built-in list of errors to
  retry. Pass a `retryIf` predicate, or use the new `ExponentialRetry.onCodes`
  constructor to retry errors with the given status codes, as `gax.OnCodes`
  does in Go. To retry the same errors as before, use the new
  `isTransientError` predicate. For example, replace
  `ExponentialRetry(maxRetries: 3)` with
  `ExponentialRetry(retryIf: isTransientError, maxRetries: 3)`.
* **Breaking:** `ExponentialRetry`, including `defaultRetry`, now randomly
  shortens each delay between retries, so that clients that fail at the same
  time don't all retry at once. The new `jitter` parameter is the fraction by
  which a delay can be shortened. It defaults to `1.0` ("full jitter", where
  each delay is chosen uniformly between zero and the calculated delay), as in
  the Python, Go and Java client libraries. Pass `jitter: 0.0` for fixed
  delays.
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
* `Storage.deleteBucket` and `Bucket.delete` are now retried by default, even
  without `ifMetagenerationMatch`, because deleting a bucket is always
  idempotent.
* `Storage.deleteObjectAcl`, `Storage.patchObjectAcl` and
  `Storage.updateObjectAcl` are no longer retried by default when `generation`
  is set, because changing an ACL is never idempotent.
* Add `isTransientError`, which returns whether an error is one that the Cloud
  Storage retry strategy considers transient. It is the predicate of
  `defaultRetry`, like `ShouldRetry` in the Go client library.
* Add `noRetry` to disable retries.
* Re-export `hasStatusCode` and `Code` from `package:google_cloud_rpc`.
* Move retry classes (`RetryRunner`, `ExponentialRetry`) and
  `ChecksumValidationException` to `package:google_cloud_rpc` (re-exported for
  backwards compatibility).
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
