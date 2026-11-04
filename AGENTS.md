## Tips

- Read the [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) before starting work.
- Run `dart format .` before declaring yourself done.
- Run `dart analyze .` and fix any issues before declaring yourself done.
- Update the package's `CHANGELOG.md` with any new features, public API
  changes, or bug fixes before declaring yourself done.
- Wrap Markdown (`*.md`) files at 80 columns.
- Update this file if you discover something useful about developing in this
  repository.
- In a sandboxed shell that cannot read the home directory, `dart` commands
  may crash while reading `~/.dart-tool/dart-flutter-telemetry.config`. Pass
  `--suppress-analytics` to avoid this (e.g.
  `dart --suppress-analytics analyze .`).

## Style

- Follow the style described in
  [Effective Dart](https://dart.dev/effective-dart):
    - AVOID starting a function or method name with `get`
    - PREFER starting a boolean variable or property comment with "Whether"
      followed by a noun or gerund phrase
- Prefer the use of `Uri.https(...)` over `Uri.parse(...)` when the scheme is
  known to be https.

## Generated code

- Regenerating the packages in `generated/` overwrites every file except those
  in the package's `keep` list in `librarian.yaml`.
- Don't edit `generated/*/CHANGELOG.md`. `librarian bump` writes the entries
  from PR titles at release time (see
  [generated/RELEASING.md](generated/RELEASING.md)).

## Testing instructions

- Run `dart test .` frequently (note the `.` when running from the root).
- Before running tests with the `-P google-cloud` flag, find the currently
  configured project using `gcloud config get-value project` and ask the
  user to confirm that this specific project is safe to use.
- Because integration tests require setting the `GOOGLE_CLOUD_PROJECT`
  environment variable, you must run the command in a shell instead of
  using the `mcp_dart_run_tests` tool. For example:
  `GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project) dart test . -P google-cloud`
  Note that this also applies to tests running against the firebase emulator
  if they use `projectId` (e.g.
  `GOOGLE_CLOUD_PROJECT=demo-project dart test -P firebase-emulator`).
- Try to fix any test failures before declaring yourself done.
- Running VM tests for packages that depend on `package:webcrypto` (e.g.
  `google_cloud_auth`) runs a native build hook that searches for build tools
  (such as CMake) outside of the repository, so `dart test` may fail in a
  sandboxed shell that restricts file system access.
