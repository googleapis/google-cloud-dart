## 0.1.0-wip

* Added `CredentialException` for errors when retrieving or using credentials.
* Added `ServiceAccountCredentials` with support for RSA-SHA256 signing.
* Added `ServiceAccountSigner` interface and `SigningException`.
* Added `ComputeEngineCredentials` implementing `ServiceAccountSigner` via the
  Google Cloud IAM `signBlob` API.
* Added `applicationDefaultCredentials()` and `defaultCredentials()` to load
  signing credentials using Application Default Credentials (ADC).


