# Developer's Guide

## Layout

- `examples/`: various examples of Google Cloud client usage
- `generated/`: the generated Google Cloud API packages (see
  [`generated/README.md`](generated/README.md) for generation instructions)
- `pkgs/`: hand-written API and support packages (see
  [`pkgs/README.md`](pkgs/README.md) for package-specific instructions)
- `tests/`: unit and integration tests for the generated cloud APIs

The dependency graph for the current set of packages:

![Dependency Graph](deps.png)

## Contributors

The ability to triage issues, merge PRs, and assign reviewers is limited to 
members of the [`cloud-sdk-dart-team`][] GitHub team.

Team members also have access to the [`dart-sdk-testing`][] Google Cloud
project, which is used for running integration tests.

PRs created by team members will automatically have Google Cloud integration
tests run for them. Team members can manually trigger Google Cloud integration
tests by commenting `/gcbrun` on the PR.

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

## Pull Requests

* PRs should follow [Conventional Commits][]
* If the PR applies to a single package, then the package name, with the
  "google_cloud" prefix removed, should be included in the PR scope. For
  example, for a documentation changes to `package:google_cloud_storage`,
  `docs(storage): clarify retry logic`.

[`cloud-sdk-dart-team`]: https://github.com/orgs/googleapis/teams/cloud-sdk-dart-team
[`dart-sdk-testing`]: https://pantheon.corp.google.com/welcome?project=dart-sdk-testing
[Google Cloud Console]: https://console.cloud.google.com/
[Conventional Commits]: https://www.conventionalcommits.org/
