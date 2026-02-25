# Google Cloud Storage Emulator Tests

Tests that verify that the Google Cloud Storage client library works correctly
with the Firebase Storage Emulator.

## Running these tests locally

To run these tests locally, the Firebase Storage Emulator must be running.

```bash
# Run inside this directory.
firebase emulators:start
```

and then:

```bash
# Run inside the google_cloud_storage directory
dart test emulator_test
```
