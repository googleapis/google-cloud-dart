## 0.6.4-wip

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
