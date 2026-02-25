# Google Cloud Storage Emulator Tests

This directory contains integration tests that verify the compatibility of
`package:google_cloud_storage` with the [Firebase Storage Emulator][].

## Running Tests Locally

To run these tests on your machine, you need to have the emulator running in one terminal session and execute the tests in another.

### 1. Start the Firebase Emulator

Navigate to this directory and start the storage emulator:

```bash
# From packages/google_cloud_storage/emulator_test
firebase emulators:start
```

### 2. Run the Tests

In a separate terminal, navigate to the root of the `google_cloud_storage` package and run the tests:

```bash
# From packages/google_cloud_storage
dart test emulator_test
```

## Known Limitations

The Firebase Storage Emulator is a high-fidelity implementation of the Cloud Storage for Firebase API, which is a subset of the full Google Cloud Storage JSON API. Consequently:

- Some advanced GCS features (e.g., Object Retention/Lock, certain IAM configurations, or specific query parameters) may return a `NotImplementedException` (HTTP 501) or `BadRequestException`.
- Always verify critical production logic against a live GCS project using the recorded API tests in the `test/` directory.

[Firebase Storage Emulator]: https://firebase.google.com/docs/emulator-suite/connect_storage