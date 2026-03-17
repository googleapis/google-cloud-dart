# Developer's Guide

## Layout

- `examples/`: various examples of Google Cloud client usage
- `generated/`: the generated Google Cloud API packages
- `packages/`: hand-written API and support packages
- `tests/`: unit and integration tests for the generated cloud APIs

The dependency graph for the current set of packages:

![Dependency Graph](deps.png)

## Testing

### Integration tests that require a Google Cloud Project

Many integration tests require access to a Google Cloud project. These
tests are **not** run by default by `dart test`.

For example,
[packages/google_cloud_storage/test/list_buckets_test.dart](packages/google_cloud_storage/test/list_buckets_test.dart). Note the
`@Tags(['google-cloud'])` annotation near the top of the file.

To run these tests locally, you must:
1. Create a Google Cloud project.
2. Set that project as your default project:
   ```bash
   $ gcloud config set project <project-id>
   ```
3. Authenticate with the project:
   ```bash
   $ gcloud auth application-default login
   ```

Some tests may require additional authentication scopes. For example, the
tests in generated/google_cloud_ai_generativelanguage_v1beta require the 
"https://www.googleapis.com/auth/generative-language" scope. You can add
additional scopes by passing the `--scopes` flag to `gcloud auth application-default login`. For example:

```bash
$ gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/generative-language
```

The most practical way of determining missing scopes is to just run the tests
and look at the failures messages. For example:

```
Access was denied (www-authenticate header was: Bearer realm="https://accounts.google.com/", error="insufficient_scope", scope="https://www.googleapis.com/auth/generative-language https://www.googleapis.com/auth/generative-language.tuning https://www.googleapis.com/auth/generative-language.tuning.readonly https://www.googleapis.com/auth/generative-language.retriever https://www.googleapis.com/auth/generative-language.retriever.readonly").
```

Likewise, some tests may require additional services to be enabled in the Google Cloud project. For example, the tests in generated/google_cloud_logging_v2/test/require the Cloud Logging API to be enabled.

Once again, you can determine missing services by running the tests and looking at the failure messages, which will contain a URL where the service can be enabled:

```
  ForbiddenException: Cloud Logging API has not been used in project <project id> before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/logging.googleapis.com/overview?project=<project id> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.
```


You can then run the tests with:

```bash
$ # You can run all of the tests from the repository root or from any package
$ # directory to run the integration tests in that directory. Running all of
$ # the tests may take a long time.
$ GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project) dart test . -P google-cloud
```



## Developing

### Librarian

[Librarian](https://github.com/googleapis/librarian/blob/main/README.md)
is the tool used to generate Dart packages from API descriptions.

#### Regenerating the Dart packages

From the root of the project:

```bash
go run github.com/googleapis/librarian/cmd/librarian@main generate -all
```

> [!NOTE]
> You will have to [update Librarian](#updating-librarian) if you want to merge these changes.

#### Regenerating from a locally modified Librarian

Clone https://github.com/googleapis/librarian as a sibling directory to this
repo, make any desired changes to Librarian, then - from the root of the
project - run:

```bash
# Build the binary
go -C ../librarian build -o ../librarian/librarian ./cmd/librarian
# Run library regeneration
../librarian/librarian generate -all -f
```
> [!NOTE]
> Use `-f` to ignore the librarian version check since the local version is likely not the same
> as the one in [librarian.yaml](librarian.yaml).

#### Updating Librarian

[Workflow automation](.github/workflows/dart_checks.yaml) ensures that all
generated code matches what the generator would actually produce.

To prevent Librarian changes from causing workflow automation failures in this
repository, the version of Librarian used by this automation is pinned.

After making changes to Librarian you must 
[regenerate the Dart packages](#regenerating-the-dart-packages) and update
the version of Librarian used in the automation:
1. Find the head version of Librarian by running this command:
   
   `GOPROXY=direct go list -m -u -f '{{.Version}}' github.com/googleapis/librarian@main`
2. Modify the Librarian invocation in [.github/workflows/dart_checks.yaml](.github/workflows/dart_checks.yaml)

#### Updating API sources

Configuration for API source descriptions is found in the `[sources]`
section of the root [`librarian.yaml`](librarian.yaml).

You can update these sources to their latest versions by running
(from the root of the project):

```bash
go run github.com/googleapis/librarian/cmd/librarian@main update conformance googleapis protobuf showcase
```

### Testing

Some generated packages contain integration tests, e.g.,
[`package:google_cloud_ai_generativelanguage_v1beta`](generated/google_cloud_ai_generativelanguage_v1beta/test/).

By default, these tests use a recorded version of the interation between the
API client and the server.

If new tests are added or the communication between the API client and the
server changes, these changes must be regenerated with:

```bash
cd generated && dart --define=http=record test . -c vm:source
```
