# Developer's Guide

## Layout

- `examples/`: various examples of Google Cloud client usage
- `generated/`: the generated Google Cloud API packages
- `packages/`: hand-written API and support packages
- `tests/`: unit and integration tests for the generated cloud APIs

## Developing

### Regenerating the Dart packages

From the root of the project:

```bash
go run github.com/googleapis/librarian/cmd/sidekick@main refreshall
```

> [!NOTE]
> You will have to [update Sidekick](#updating-sidekick) if you want to merge these changes.

### Regenerating from a locally modified Sidekick

Clone https://github.com/googleapis/librarian as a sibling directory to this
repo, make any desired changes to Sidekick, then - from the root of the
project - run:

```bash
go -C ../librarian run ./cmd/sidekick refreshall -project-root $PWD
```

### Updating Sidekick

[Workflow automation](.github/workflows/dart_checks.yaml) ensures that all
generated code matches what the generator would actually produce.

To prevent Sidekick changes from causing workflow automation failures in this
repository, the version of Sidekick used by this automation is pinned.

After making changes to Sidekick you must 
[regenerate the Dart packages](#regenerating-the-dart-packages) and update
the version of Sidekick used in the automation:
1. Find the head version of Sidekick by running this command:
   
   `GOPROXY=direct go list -m -u -f '{{.Version}}' github.com/googleapis/librarian@main`
2. Modify the Sidekick invocation in [.github/workflows/dart_checks.yaml](.github/workflows/dart_checks.yaml)

### Updating API sources

Configuration for API source descriptions is found in the `[source]`
section of the root [`.sidekick.toml`](.sidekick.toml).

You can update these sources to their latest versions by running
(from the root of the project):

```bash
go run github.com/googleapis/librarian/cmd/sidekick@main update
```
