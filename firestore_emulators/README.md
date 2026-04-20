# Firebase Emulator Tests

This directory contains configuration for running tests that target
the [Firebase Emulators Suite][].

## Running Tests Locally

To run these tests on your machine, you need to have the emulator running in
one terminal session and execute the tests in another.

### 1. Start the Firebase Emulator

Navigate to this directory and start the emulator:

```bash
firebase emulators:start
```

### 2. Run the Tests

In a separate terminal, navigate to the root of the repository and run the
tests:

```bash
GOOGLE_CLOUD_PROJECT=test-project \
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
STORAGE_EMULATOR_HOST=127.0.0.1:9199 \
  dart test -P firebase-emulator .
```

[Firebase Emulators Suite]: https://firebase.google.com/docs/emulator-suite
