## Tips

- Read the [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) before starting work.
- Run `dart format .` before declaring yourself done.
- Run `dart analyze .` and fix any issues before declaring yourself done.
- Update the package's `CHANGELOG.md` with any new features, public API
  changes, or bug fixes before declaring yourself done.
- Wrap Markdown (`*.md`) files at 80 columns.
- After changing a file under `pkgs/*/example/`, run
  `dart run tool/update_excerpts.dart` to update the `README.md` code excerpts
  (CI fails if they are out of date).
- Update this file if you discover something useful about developing in this
  repository.

## Style

- Follow the style described in
  [Effective Dart](https://dart.dev/effective-dart):
    - AVOID starting a function or method name with `get`
    - PREFER starting a boolean variable or property comment with "Whether"
      followed by a noun or gerund phrase
- Prefer the use of `Uri.https(...)` over `Uri.parse(...)` when the scheme is
  known to be https.
- `package:google_cloud_protobuf/protobuf.dart` exports a protobuf `Duration`
  that silently shadows `dart:core`'s `Duration`. Import it with `show` (or
  `hide Duration`) in libraries that use `dart:core`'s `Duration`.
- Don't use `async*` for a stream that holds a request or response open. A
  generator that is suspended at an `await` (including in an `await for` loop)
  doesn't notice that its subscription was cancelled until the `await`
  completes, so `cancel()` can hang and the connection stays open. Use a
  `StreamController` or stream transformations instead.
- dartdoc resolves references in `{@macro}` text in the library that uses the
  macro, and ignores that library's `@docImport`s. Use backticks instead of a
  reference for names that aren't imported everywhere a template is used, and
  check with `dart doc --dry-run`.

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
