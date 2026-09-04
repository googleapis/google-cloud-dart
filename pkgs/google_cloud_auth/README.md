[![pub package](https://img.shields.io/pub/v/google_cloud_auth.svg)](https://pub.dev/packages/google_cloud_auth)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_auth.svg)](https://pub.dev/packages/google_cloud_auth/publisher)

Authentication and credential management for Google Cloud.

> [!NOTE]
> This package is currently experimental and published under the
> [labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order
> to solicit feedback.
>
> For packages in the labs.dart.dev publisher we generally plan to either
> graduate the package into a supported publisher (dart.dev, tools.dart.dev)
> after a period of feedback and iteration, or discontinue the package.
> These packages have a much higher expected rate of API and breaking changes.
>
> Your feedback is valuable and will help us evolve this package. For general
> feedback, suggestions, and comments, please file an issue in the
> [bug tracker](https://github.com/googleapis/google-cloud-dart/issues).

## Features

- **Service Account Credentials**: Load service account credentials from a JSON
  file, JSON string, parsed map, or PKCS#8 PEM private key.
- **Compute Engine Credentials**: Use credentials from the Google Compute Engine
  (or Cloud Run / Cloud Build) metadata server and sign payloads via the Google
  Cloud IAM `signBlob` API.
- **Application Default Credentials**: Automatically find and load credentials
  capable of signing messages using `applicationDefaultCredentials()`.
- **Cryptographic Signing**: Sign arbitrary payloads using
  `ServiceAccountSigner` implemented by both `ServiceAccountCredentials` (local
  RSA-SHA256) and `ComputeEngineCredentials` (remote IAM `signBlob`).

## Usage

### Signing with Application Default Credentials

```dart
import 'dart:convert';

import 'package:google_cloud_auth/google_cloud_auth.dart';

Future<void> main() async {
  // Resolves credentials from GOOGLE_APPLICATION_CREDENTIALS, the gcloud
  // well-known file, or the Compute Engine metadata server.
  final signer = await applicationDefaultCredentials();

  print('Signer email: ${signer.clientEmail}');

  final message = utf8.encode('Hello from Application Default Credentials');
  final signature = await signer.sign(message);
  print('Signature generated (${signature.length} bytes)');
}
```

### Loading Service Account Credentials

<?code-excerpt "example/main.dart (main)"?>
```dart
import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_auth/google_cloud_auth.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run example/main.dart <path-to-service-account.json>',
    );
    exitCode = 1;
    return;
  }

  final path = args.first;
  final credentials = await ServiceAccountCredentials.fromServiceAccountFile(
    path,
  );

  print('Service Account Email : ${credentials.clientEmail}');
  print('Project ID            : ${credentials.projectId ?? '(not set)'}');
  print('Client ID             : ${credentials.clientId ?? '(not set)'}');
  print('Private Key ID        : ${credentials.privateKeyId ?? '(not set)'}');
  print('Token URI             : ${credentials.tokenUri}');
  print('Universe Domain       : ${credentials.universeDomain}');

  final sampleMessage = utf8.encode('Hello from google_cloud_auth');
  final signature = await credentials.sign(sampleMessage);
  print(
    'Sample Signature (b64): ${base64.encode(signature).substring(0, 32)}...',
  );
}
```
