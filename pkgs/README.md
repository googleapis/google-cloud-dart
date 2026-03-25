# Hand-written packages

This directory contains hand-written API and support packages.

## Testing

### Running against Storage Testbench

Some integration tests in `package:google_cloud_storage` use the
[Storage Testbench][]. These tests are tagged with
`@Tags(['storage-testbench'])` and are not run by default, i.e., `dart test`
will not run them.

To run these tests locally (they are automatically run for PRs using a
[GitHub workflow](../.github/workflows/dart_checks.yaml)):

1.  **Start Storage Testbench:**
    ```bash
    $ docker run -d --rm -p 9000:9000 -p 8888:8888 \
        gcr.io/cloud-devrel-public-resources/storage-testbench:latest
    ```

2.  **Run the tests:**
    ```bash
    $ dart test . -P storage-testbench
    ```

[Storage Testbench]: https://github.com/googleapis/storage-testbench
