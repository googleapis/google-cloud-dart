# Generated packages

This directory contains Google Cloud API packages that are automatically
generated from API descriptions using
[Librarian](https://github.com/googleapis/librarian).

## Releasing and Updating

To update Librarian or API sources, regenerate packages, or create a release,
see the step-by-step process in [RELEASING.md](RELEASING.md).

## Local Development

### Regenerating from a locally modified Librarian

When developing changes in Librarian itself, clone
https://github.com/googleapis/librarian as a sibling directory to this repo,
make your changes, then build and run Librarian locally:

```bash
# Build the binary
go -C ../librarian build -o ../librarian/librarian ./cmd/librarian

# Run library regeneration (-f ignores the librarian version check)
../librarian/librarian generate -all
```

