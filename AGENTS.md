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

## Generated code

- Regenerating the packages in `generated/` overwrites every file except those
  in the package's `keep` list in `librarian.yaml`.
- Don't edit `generated/*/CHANGELOG.md`. `librarian bump` writes the entries
  from PR titles at release time (see
  [generated/RELEASING.md](generated/RELEASING.md)).
- `package:google_cloud_protobuf/protobuf.dart` exports
  `google.protobuf.Duration` as `Duration`, which shadows `dart:core`'s
  `Duration` in generated code. To use `dart:core`'s, write `$core.Duration`
  and add both `import 'dart:core' as $core;` and `import 'dart:core';` (an
  explicit `dart:core` import disables the implicit one).
- `ProtoEnum` (the base of enums such as `Code`) overrides `==`, so enum
  values can't be elements of `const` sets or keys of `const` maps. Use `const`
  lists instead.

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
