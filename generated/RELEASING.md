
# Releasing Generated Packages

This document describes how to update API descriptions and release generated
packages. All commands should be run from the repository root.

## Prerequisites

Install `dart_apitool` (used to identify breaking changes):

```bash
dart pub global activate dart_apitool
```

## 1. Upgrade to the latest version of Librarian

Find the latest version of Librarian on `@main`:

```bash
export LIBRARIAN_VERSION=$(GOPROXY=direct go list -m -u -f '{{.Version}}' \
  github.com/googleapis/librarian@main)
echo $LIBRARIAN_VERSION
```

Update the version in both:
- `LIBRARIAN_VERSION` in
  [`.github/workflows/dart_checks.yaml`](../.github/workflows/dart_checks.yaml)
- The top-level `version` field in [`../librarian.yaml`](../librarian.yaml)

## 2. Update API sources (optional)

Update the API source descriptions in [`../librarian.yaml`](../librarian.yaml)
to their latest versions:

```bash
go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} \
  update \
  sources.conformance sources.googleapis sources.protobuf sources.showcase
```

## 3. Regenerate the Dart packages

Regenerate all packages, tidy configuration, and update documentation:

```bash
go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} \
  generate -all
go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} \
  tidy
dart run tool/update_docs.dart
```

## 4. Create a PR and merge it

1. Verify that all tests and analysis pass locally:
   ```bash
   dart analyze
   dart test .
   ```
2. Commit the changes and open a pull request against `main`. Use a commit
   message that describes the functionality added from the point-of-view of
   the developer, e.g., "feat: add setup and test agentic skills".

> [!TIP]
> Steps 1–4 can and should be done multiple times (as needed) prior to
> creating a release. Each PR adds changelog entries to affected packages.
> For example, if you update librarian to add a picture of a cat in the
> `README.md` of the generated packages, you could perform steps 1, 3, and 4
> with the PR title `"docs: add a picture of a cat to README.md"`. When
> released, each package will have a `CHANGELOG.md` entry like:
>
> ```markdown
> - docs: add a picture of a cat to README.md
> ```

## 5. Update version information

Update the version of each package according to semver and write a
`CHANGELOG.md` entry for every relevant PR since the last release.

1. Run librarian:
  ```bash
  go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} bump --all
  ```
2. Verify that all tests and analysis pass locally:
   ```bash
   dart analyze
   dart test .
   ```
3. Commit the changes and open a pull request against `main`. The commit
   message will not appear in any `CHANGELOG.md`.
