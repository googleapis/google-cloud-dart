---
name: google-cloud-firestore-v1-setup
description: >-
  Use this skill to help the developer get started with
  package:google_cloud_firestore_v1
---

## Getting Started with package:google_cloud_firestore_v1

### 1. Add the package to your pubspec.yaml

```shell
dart pub add google_cloud_firestore_v1
```

### 2. Import the library

In your Dart code, import the library:

```dart
import 'package:google_cloud_firestore_v1/firestore.dart';
```

### 3. Initialize the client

To call the client, you need to create an instance of the service that
you want to use, e.g., `Firestore`.

There are two ways of creating an instance with the necessary credentials.

#### Option A: Using Application Default Credentials (ADC) (Recommended)

Recommended for production environments, server-side backends, and when
running on Google Cloud (such as Cloud Run, GCE, GKE).

When running on Google Cloud, Application Default Credentials are automatically
available.

When running locally, the `gcloud` command must be available (see
[Install the Google Cloud CLI](https://docs.cloud.google.com/sdk/docs/install-sdk)).
To obtain Application Default Credentials, run:

```shell
gcloud auth application-default login
```

Add `googleapis_auth` to your dependencies:

```shell
dart pub add googleapis_auth
```

```dart
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_cloud_firestore_v1/firestore.dart';

Future<void> main() async {
  final authClient = await clientViaApplicationDefaultCredentials(
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  final client = Firestore(client: authClient);

  try {
    // Call a method on the client.
    final response = await client.getDocument(
      GetDocumentRequest(),
    );
    print('Response: $response');
  } finally {
    // Always close the client to release resources.
    client.close();
  }
}
```

#### Option B: Using an API Key (Simple)

Recommended for quick testing or prototyping because the setup is simple.

If the user does not have an API key, then they can obtain one using the
[Google Cloud Console](https://console.cloud.google.com/apis/credentials).

Add the API key to one of these environment variables:
- `GOOGLE_API_KEY`


```dart
import 'package:google_cloud_firestore_v1/firestore.dart';

Future<void> main() async {
  final client = Firestore.fromApiKey();

  try {
    // Call a method on the client.
    final response = await client.getDocument(
      GetDocumentRequest(),
    );
    print('Response: $response');
  } finally {
    // Always close the client to release resources.
    client.close();
  }
}
```

