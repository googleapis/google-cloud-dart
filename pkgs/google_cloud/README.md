[![pub package](https://img.shields.io/pub/v/google_cloud.svg)](https://pub.dev/packages/google_cloud)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud.svg)](https://pub.dev/packages/google_cloud/publisher)

> NOTE: This is a **community-supported project**, meaning there is no official
> level of support. The code is not covered by any SLA or deprecation policy.
>
> Feel free to open [issues] for bugs and feature requests.

Utilities for running Dart code correctly on the Google Cloud Platform.

## Features

- **Project Discovery**: Automatically discover the Google Cloud [Project ID] using multiple strategies:
  - Environment variables (e.g., `GOOGLE_CLOUD_PROJECT`).
  - Service account credentials file (`GOOGLE_APPLICATION_CREDENTIALS`).
  - `gcloud` CLI configuration.
  - Google Cloud [Metadata Server].
- **Metadata API**: Flexible access to the [Metadata Server] with built-in
  caching (`getMetadataValue`) or direct fetching (`fetchMetadataValue`).
- **Identity Discovery**: Retrieve the default [service account email].
- **Core**: Low-level utilities for Google Cloud libraries.

## Usage

### Project Discovery

<?code-excerpt "example/project_discovery.dart (project-discovery)"?>
```dart
import 'package:google_cloud/google_cloud.dart';

void main() async {
  // Discovers the project ID using all available strategies.
  // Discovery via the Metadata Server is cached for the lifetime of the
  // process.
  final projectId = await computeProjectId();
  print('Running in project: $projectId');
}
```

[Project ID]:
  https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects
[Metadata Server]:
  https://docs.cloud.google.com/compute/docs/metadata/overview
[service account email]:
  https://docs.cloud.google.com/compute/docs/access/authenticate-workloads#applications
[issues]: https://github.com/googleapis/google-cloud-dart/issues
