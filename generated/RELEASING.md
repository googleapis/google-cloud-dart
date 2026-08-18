
## Install prerequesits

dart pub global activate dart_apitool

# 1: Upgrade to the latest version of librarian

```bash
export LIBRARY_VERSION=$(go list -m -u -f '{{.Version}}' github.com/googleapis/librarian@main)
echo $LIBRARY_VERSION
```

Update the `LIBRARIAN_VERSION` environment variable in
[.github/workflows/dart_checks.yaml](../.github/workflows/dart_checks.yaml).

# 2: Update API sources

```bash
go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} update sources.conformance sources.googleapis sources.protobuf sources.showcase
```

> [!NOTE]
> Configuration for API source descriptions is found in the `[sources]`
> section of the root [`../librarian.yaml`](../librarian.yaml).

# 3: Regenerate the Dart packages

```bash
go run github.com/googleapis/librarian/cmd/librarian@${LIBRARIAN_VERSION} generate --all
```

# 4: Create a PR and merge it

TODO: what details do I need here?

> [!TIP]
> Steps 1-4 can and should be done multiple times (as needed) prior to
> creating the release. Each PR will add a `CHANGELOG.md` entry to
> affected generated packages.
