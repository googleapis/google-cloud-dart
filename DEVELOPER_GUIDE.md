# Developer's Guide

## Layout

- `examples/`: various examples of Google Cloud client usage
- `generated/`: the generated Google Cloud API packages (see
  [`generated/README.md`](generated/README.md) for generation instructions)
- `pkgs/`: hand-written API and support packages (see
  [`pkgs/README.md`](pkgs/README.md) for package-specific instructions)
- `tests/`: unit and integration tests for the generated cloud APIs

The dependency graph for the current set of packages:

<!-- DEPS_DIAGRAM_START -->
```mermaid
graph TD
  subgraph Tier0 ["Tier 0 (Publish First)"]
    google_cloud["google_cloud"]
    google_cloud_protobuf["protobuf"]
  end

  subgraph Tier1 ["Tier 1"]
    google_cloud_api["api"]
    google_cloud_common["common"]
    google_cloud_logging_type["logging_type"]
    google_cloud_rpc["rpc"]
    google_cloud_type["type"]
  end

  subgraph Tier2 ["Tier 2"]
    google_cloud_iam_v1["iam_v1"]
    google_cloud_language_v2["language_v2"]
    google_cloud_location["location"]
    google_cloud_longrunning["longrunning"]
    google_cloud_pubsub["pubsub"]
    google_cloud_storage["storage"]
  end

  subgraph Tier3 ["Tier 3"]
    google_cloud_ai_generativelanguage_v1beta["ai_generativelanguage_v1beta"]
    google_cloud_aiplatform_v1beta1["aiplatform_v1beta1"]
    google_cloud_firestore_v1["firestore_v1"]
    google_cloud_functions_v2["functions_v2"]
    google_cloud_logging_v2["logging_v2"]
    google_cloud_secretmanager_v1["secretmanager_v1"]
  end

  subgraph Tier4 ["Tier 4"]
    google_cloud_logging["logging"]
  end

  subgraph Tier5 ["Tier 5 (Publish Last)"]
    google_cloud_shelf["shelf"]
  end

  google_cloud_ai_generativelanguage_v1beta --> google_cloud_longrunning
  google_cloud_ai_generativelanguage_v1beta --> google_cloud_protobuf
  google_cloud_ai_generativelanguage_v1beta --> google_cloud_rpc
  google_cloud_ai_generativelanguage_v1beta --> google_cloud_type
  google_cloud_aiplatform_v1beta1 --> google_cloud_api
  google_cloud_aiplatform_v1beta1 --> google_cloud_iam_v1
  google_cloud_aiplatform_v1beta1 --> google_cloud_location
  google_cloud_aiplatform_v1beta1 --> google_cloud_longrunning
  google_cloud_aiplatform_v1beta1 --> google_cloud_protobuf
  google_cloud_aiplatform_v1beta1 --> google_cloud_rpc
  google_cloud_aiplatform_v1beta1 --> google_cloud_type
  google_cloud_api --> google_cloud_protobuf
  google_cloud_common --> google_cloud_protobuf
  google_cloud_firestore_v1 --> google_cloud_longrunning
  google_cloud_firestore_v1 --> google_cloud_protobuf
  google_cloud_firestore_v1 --> google_cloud_rpc
  google_cloud_firestore_v1 --> google_cloud_type
  google_cloud_functions_v2 --> google_cloud_iam_v1
  google_cloud_functions_v2 --> google_cloud_location
  google_cloud_functions_v2 --> google_cloud_longrunning
  google_cloud_functions_v2 --> google_cloud_protobuf
  google_cloud_functions_v2 --> google_cloud_rpc
  google_cloud_functions_v2 --> google_cloud_type
  google_cloud_iam_v1 --> google_cloud_protobuf
  google_cloud_iam_v1 --> google_cloud_rpc
  google_cloud_iam_v1 --> google_cloud_type
  google_cloud_language_v2 --> google_cloud_protobuf
  google_cloud_language_v2 --> google_cloud_rpc
  google_cloud_location --> google_cloud_protobuf
  google_cloud_location --> google_cloud_rpc
  google_cloud_logging --> google_cloud_logging_type
  google_cloud_logging --> google_cloud_logging_v2
  google_cloud_logging --> google_cloud_protobuf
  google_cloud_logging_type --> google_cloud_protobuf
  google_cloud_logging_v2 --> google_cloud_api
  google_cloud_logging_v2 --> google_cloud_logging_type
  google_cloud_logging_v2 --> google_cloud_longrunning
  google_cloud_logging_v2 --> google_cloud_protobuf
  google_cloud_logging_v2 --> google_cloud_rpc
  google_cloud_longrunning --> google_cloud_protobuf
  google_cloud_longrunning --> google_cloud_rpc
  google_cloud_pubsub --> google_cloud
  google_cloud_pubsub --> google_cloud_protobuf
  google_cloud_pubsub --> google_cloud_rpc
  google_cloud_rpc --> google_cloud_protobuf
  google_cloud_secretmanager_v1 --> google_cloud_iam_v1
  google_cloud_secretmanager_v1 --> google_cloud_location
  google_cloud_secretmanager_v1 --> google_cloud_protobuf
  google_cloud_secretmanager_v1 --> google_cloud_rpc
  google_cloud_shelf --> google_cloud_logging
  google_cloud_storage --> google_cloud
  google_cloud_storage --> google_cloud_protobuf
  google_cloud_storage --> google_cloud_rpc
  google_cloud_type --> google_cloud_protobuf
```
<!-- DEPS_DIAGRAM_END -->

## Testing

Code changes should be covered by tests. Prefer integration tests to mocks
when writing tests for code that communicates directly with Google Cloud
services.

### Running against Google Cloud

Some integration tests require access to a real Google Cloud project. These
tests are tagged with `@Tags(['google-cloud'])` and are not run by default,
i.e., `dart test` will not run them.

To run these tests locally (they are automatically run for PRs using
[Google Cloud Build](.gcb)):

1.  **Configure your project:**
    ```bash
    $ gcloud config set project <project-id>
    ```

> [!NOTE]
> You can create a new Google Cloud project for testing using the
> [Google Cloud Console].

2.  **Authenticate:**
    ```bash
    $ gcloud auth application-default login
    ```

> [!NOTE]
> Some tests may require additional scopes. For example:
> ```bash
> $ gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/generative-language
> ```

3.  **Run the tests:**
    ```bash
    $ # NOTE: you can run this command in the repository root directory (to
    $ # run all tests) or in any subdirectory (to run only the tests in that
    $ # subdirectory).
    $ GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project) dart test . -P google-cloud
    ```

#### Troubleshooting

*   **Missing Scopes:** If a test fails with `insufficient_scope`, check the error message for the required scope URL and re-authenticate with that scope.
*   **Disabled APIs:** If a test fails with a `ForbiddenException` stating an API has not been used, follow the URL in the error message to enable the API in the Google Cloud Console.

### Running against the Firebase Emulators Suite

Some integration tests require access to the [Firebase Emulators Suite][]. These
tests are tagged with `@Tags(['firebase-emulator'])` and are not run by default,
i.e., `dart test` will not run them.

To run these tests locally (they are automatically run for PRs using a GitHub workflow):

```bash
$ firebase emulators:exec \
    --config=firestore_emulators/firebase.json \
    "GOOGLE_CLOUD_PROJECT=test-project dart test -P firebase-emulator ."
```

See the [Firebase emulator configuration](firestore_emulators/).

## Pull Requests

* PRs should follow [Conventional Commits][]
* If the PR applies to a single package, then the package name, with the
  "google_cloud" prefix removed, should be included in the PR scope. For
  example, for a documentation changes to `package:google_cloud_storage`,
  `docs(storage): clarify retry logic`.

## Publishing Packages

Package publishing is automated using GitHub Actions and the shared
[ecosystem workflows](https://github.com/dart-lang/ecosystem).

### Pull Requests (Dry Run)
When a PR is opened or updated on `main`, the
[Publish workflow](file:///Users/kevmoo/github/google-cloud-dart/.github/workflows/publish.yaml)
runs a dry-run check for all packages in the repository. It validates that
there are no issues that would prevent publishing to `pub.dev`
(`dart pub publish --dry-run`).

### Enabling Automated Publishing on pub.dev

Before GitHub Actions can publish a package to `pub.dev`, you must authorize
the GitHub repository on the `pub.dev` website. This configuration is derived
from the [official Dart documentation][automated-publishing-docs].

> [!NOTE]
> The **Admin** tab on `pub.dev` is only available for packages that have
> already been published. For a new package, the first version must be
> published manually before automated publishing can be configured.

1. **Ensure Permissions:** You must be an admin of the verified publisher that
   owns the package.
2. **Navigate to Package Admin:** Go to the **Admin** tab of the package on
   `pub.dev` (e.g., `https://pub.dev/packages/<package_name>/admin`).
3. **Enable GitHub Actions:** Locate the **Automated publishing** section and
   click **Enable publishing from GitHub Actions**.
4. **Configure Repository & Tags:**
   - **Repository:** Enter `googleapis/google-cloud-dart`.
   - **Tag pattern:** Because this is a monorepo, use a pattern matching the
     package-specific tag prefix: `<package_name>-v{{version}}` (e.g.,
     `google_cloud_storage-v{{version}}` or `google_cloud-v{{version}}`).
5. **Save:** Save the settings.

Once configured, `pub.dev` will authenticate and accept automated publishing
requests from GitHub Actions via OIDC whenever a matching git tag is pushed.

### Triggering a Release (Tagging)
To publish a package to `pub.dev`, a git tag matching the package name and
version must be created and pushed.

There are two ways to do this:

#### Option A: Via the PR Comment UI (Recommended)
When a PR is created or updated with a version bump, the dry-run workflow
detects it and posts a summary comment on the PR.

1. In the PR's health/publish summary comment, locate the packages table.
2. For any package ready to publish, click the pre-constructed **Publish** link
   in the table.
3. This opens GitHub's **Draft a new release** page with the correct tag name
   (`<package_name>-v<version>`), target branch, and release title already
   pre-filled.
4. Click **Publish release** in the GitHub UI to create the tag automatically.

This method is highly recommended as it avoids manual terminal execution and
prevents tag naming typos.

#### Option B: Manual Tagging (CLI)
Alternatively, you can manually create and push the tag from your terminal:

- **Tag Format:** `<package_name>-v<version>` (e.g., `google_cloud-v1.0.0` or
  `google_cloud_storage-v0.2.1`).
- **Publish Command:**
  ```bash
  git tag google_cloud_storage-v0.2.1
  git push origin google_cloud_storage-v0.2.1
  ```

When this tag is pushed to GitHub, the workflow:
1. Identifies the target package based on the `<package_name>` prefix in the
   tag.
2. Uses OIDC authentication to securely publish the package directly to
   `pub.dev`.

> [!NOTE]
> - Packages with `publish_to: none` in their `pubspec.yaml` are
>   automatically ignored.
> - The `generated/` directory is explicitly excluded from publishing in this
>   repository (`ignore-packages: generated/**` in
>   [publish.yaml](file:///Users/kevmoo/github/google-cloud-dart/.github/workflows/publish.yaml)).
> - Version numbers ending with `-dev` (e.g., `1.2.3-dev`) are validated but
>   **not** auto-published to `pub.dev`.

## Maintainers

The ability to triage issues, merge PRs, and assign reviewers is limited to 
members of the [`cloud-sdk-dart-team`][] GitHub team.

Team members also have access to the [`dart-sdk-testing`][] Google Cloud
project, which is used for running integration tests.

PRs created by team members will automatically have Google Cloud integration
tests run for them. Team members can manually trigger Google Cloud integration
tests by commenting `/gcbrun` on the PR.

[Google Cloud Console]: https://console.cloud.google.com/
[Conventional Commits]: https://www.conventionalcommits.org/
[`cloud-sdk-dart-team`]: https://github.com/orgs/googleapis/teams/cloud-sdk-dart-team
[`dart-sdk-testing`]: https://pantheon.corp.google.com/welcome?project=dart-sdk-testing
[Firebase Emulators Suite]: https://firebase.google.com/docs/emulator-suite
[automated-publishing-docs]: https://dart.dev/tools/pub/automated-publishing#configuring-automated-publishing-from-github-actions-on-pub-dev
