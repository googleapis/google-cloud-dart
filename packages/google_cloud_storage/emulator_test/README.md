# Google Cloud Storage Emulator Tests

This directory contains integration tests that verify the compatibility of
`package:google_cloud_storage` with the [Firebase Storage Emulator][].

These tests are not meant to be comprehensive and the
[Firebase Storage Emulator][] only supports a small subset of the full
Google Cloud Storage API.

## Running Tests Locally

To run these tests on your machine, you need to have the emulator running in
one terminal session and execute the tests in another.

### 1. Start the Firebase Emulator

Navigate to this directory and start the storage emulator:

```bash
# From packages/google_cloud_storage/emulator_test
firebase emulators:start
```

### 2. Run the Tests

In a separate terminal, navigate to the root of the `google_cloud_storage`
package and run the tests:

```bash
# From packages/google_cloud_storage
dart test emulator_test
```

[Firebase Storage Emulator]: https://firebase.google.com/docs/emulator-suite/connect_storage
