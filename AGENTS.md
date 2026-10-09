## Tips

- Read the [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) before starting work.
- Run `dart format .` before declaring yourself done.
- Run `dart analyze .` and fix any issues before declaring yourself done.
- Update the package's `CHANGELOG.md` with any new features, public API
  changes, or bug fixes before declaring yourself done.
- Wrap Markdown (`*.md`) files at 80 columns.
- Update this file if you discover something useful about developing in this
  repository.

## Style

- Follow the style described in
  [Effective Dart](https://dart.dev/effective-dart):
    - Do not prefix functions and methods with "get".
- Prefer the use of `Uri.https(...)` over `Uri.parse(...)` when the scheme is
  known to be https.

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

## Pull requests and publishing

- After creating a PR or pushing new commits to a PR, comment `/gcbrun`
  (`gh pr comment <PR> --body "/gcbrun"`) to trigger the required Google Cloud
  Build integration test check.
- To release and tag hand-written packages (`pkgs/`), follow
  [Publishing Packages](DEVELOPER_GUIDE.md#publishing-packages) in
  `DEVELOPER_GUIDE.md`.
- To release and tag generated packages (`generated/`), follow
  [`generated/RELEASING.md`](generated/RELEASING.md).
