## 0.1.0-wip

* Support for key signing using both `ComputeEngineCredentials` and
  `ServiceAccountCredentials`.
* Support for verifying ID tokens signed with keys published at a JWKS
  endpoint, using `TokenVerifier`.
* Support for user credentials, such as those created by
  `gcloud auth application-default login`, using `UserCredentials`.
  `defaultCredentials` returns `UserCredentials` for `authorized_user`
  credential files.
