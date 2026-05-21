## Tips

- Read the [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) before starting work.
- Run `dart format .` before declaring yourself done.
- Run `dart analyze .` and fix any issues before declaring yourself done.
- Update this file if you discover something useful about developing in this
  repository.

## Testing instructions

- Run `dart test` frequently.
- Before running tests with the `-P google-cloud` flag, find the currently
  configured project using `gcloud config get-value project` and ask the
  user to confirm that this specific project is safe to use.
- Because integration tests require setting the `GOOGLE_CLOUD_PROJECT`
  environment variable, you must run the command in a shell instead of
  using the `mcp_dart_run_tests` tool. For example:
  `GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project) dart test . -P google-cloud`
  Note that this also applies to tests running against the firebase emulator if they use `projectId` (e.g. `GOOGLE_CLOUD_PROJECT=demo-project dart test -P firebase-emulator`).
- Try to fix any test failures before declaring yourself done.
