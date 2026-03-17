## Tips

- Run `dart format .` before declaring yourself done.
- Run `dart analyze .` and fix any issues before declaring yourself done.
- Update this file if you discover something useful about developing in this
  repository.

## Testing instructions

- Run `dart test -p vm` and `dart test -p chrome` frequently.
- Many important tests require a configured Google Cloud project. Ask for
  confirmation before running these tests at least once per session. These
  tests can be run with:

  ```bash
    GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project) dart test . -P google-cloud
  ```
- Try to fix any test failures before declaring yourself done.
- Add or update tests for the code you change, even if nobody asked.

## PR

- PRs should follow [Conventional Commits][]
- If the PR applies to a single package, then the package name should be
  included in the PR scope. For example, for changes to
  `google_cloud_storage`, "docs(storage): ...".

[Conventional Commits]: https://www.conventionalcommits.org/
