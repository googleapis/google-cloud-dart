## 0.6.0

* **BREAKING:** Rename `Storage.insertObject` to `Storage.uploadObject`.
* Add `Storage.uploadObjectFromString`.
* Add `StorageObject.uploadFromString`.
* Required `google_cloud: '>=0.3.0 <0.5.0'`.

## 0.5.1

* Add support for using a `Future<Client>` in the `Storage` factory.

## 0.5.0

* Initial release for Dart 3. Support for basic Google Cloud Storage features:
  * Buckets (create, delete, get metadata, list, patch metadata)
  * Objects (create, delete, get metadata, list, patch metadata, read)

> [!NOTE]
> Versions 0.1.0 to 0.4.1-pre2 were released by Thomas Stephenson (thanks
> Thomas!) and supported Dart 1.
