[![pub package](https://img.shields.io/pub/v/google_cloud_shelf.svg)](https://pub.dev/packages/google_cloud_shelf)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_shelf.svg)](https://pub.dev/packages/google_cloud_shelf/publisher)

> [!NOTE]
> This package is currently experimental and published under the
> [labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order
> to solicit feedback.
>
> For packages in the labs.dart.dev publisher we generally plan to either
> graduate the package into a supported publisher (dart.dev, tools.dart.dev)
> after a period of feedback and iteration, or discontinue the package.
> These packages have a much higher expected rate of API and breaking changes.
>
> Your feedback is valuable and will help us evolve this package. For general
> feedback, suggestions, and comments, please file an issue in the
> [bug tracker](https://github.com/googleapis/google-cloud-dart/issues).

A package for serving HTTP requests on Google Cloud Platform using the `shelf`
framework. It is tailored for Google Cloud environments like Cloud Run, Cloud
Functions, and GKE, providing structured logging, trace correlation, exception
mapping, and graceful shutdown orchestration.

## Features

* **Google Cloud Structured Logging:** Integrates Shelf middleware
  (`createLoggingMiddleware`, `cloudLoggingMiddleware`,
  `errorLoggingMiddleware`) that automatically formats application and error
  logs in GCP's native structured format.
* **Trace Correlation:** Automatically parses W3C trace context
  headers (`traceparent`). Any log entry emitted using
  `StructuredLogger` or standard `print()` within request execution is correlated
  and nested directly under the HTTP request log entry in the Cloud Logging
  viewer.
* **Standardized HTTP Exception Mapping:** Throw client-safe exceptions in your
  handlers using `HttpResponseException`. Common factory constructors (e.g.,
  `badRequest`, `unauthorized`, `notFound`, `tooManyRequests`,
  `internalServerError`) allow returning clean, structured JSON/text status
  payloads safely, without leaking internal backend details.
* **Graceful Termination & Serving:** Environment-aware port resolution (using
  the `PORT` environment variable) and signal-aware serving (`SIGTERM` and
  `SIGINT` signal watch), ensuring requests finish before container shutdown.

## Usage

### 1. Basic Setup

Integrate `createLoggingMiddleware` in your pipeline and use `serveHandler` to
launch the server. By default, this parses the port from the `PORT` environment
variable (falling back to `8080`) and listens on all IP addresses.

<?code-excerpt "example/example.dart (basic-setup)"?>
```dart
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware())
      .addHandler((_) => Response.ok('Hello, World!'));

  await serveHandler(handler);
}
```

### 2. Contextual Logging & Trace Correlation

Enable request-log nesting in the Google Cloud Console by providing a
`projectId` to `createLoggingMiddleware`. Any logs written using `StructuredLogger`
or sent to standard `print()` inside the handler's execution flow are grouped
with the request log.

<?code-excerpt "example/contextual_logging.dart (contextual-logging)"?>
```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';

const _logger = StructuredLogger();

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware(projectId: 'my-gcp-project-id'))
      .addHandler(_userHandler);

  await serveHandler(handler);
}

Response _userHandler(Request request) {
  // Structured logs generated in the context of a request will be correlated
  // with that request in the Google Cloud Logs Explorer.
  _logger.info('Fetching user profile from database.');

  // A simple print statement is also captured as an INFO log with trace
  // correlation
  print('This print statement is correlated too!');

  // Business logic here...
  _logger.info({
    'message': 'User successfully retrieved.',
    'userId': 'user_123',
  });

  return Response.ok('User Profile');
}
```

> [!NOTE]
> When running in a Google Cloud environment (with a `projectId` provided),
> successful HTTP request access logs are automatically captured by the Google
> Cloud host infrastructure (such as the Cloud Run Load Balancer).
> Therefore, `cloudLoggingMiddleware` intentionally avoids outputting successful
> access log statements to prevent duplicate request logging.

### 3. Standardized Error & Exception Handling

Use `HttpResponseException` to return standard client-facing error codes and
messages. Unhandled exceptions (e.g., network failures) are caught, logged
with their full stack trace to the server logs, and safely mapped to a generic
`500 Internal Server Error` response to prevent data leaks.

<?code-excerpt "example/error_handling.dart (error-handling)"?>
```dart
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';

Response _profileHandler(Request request) {
  final userId = request.url.queryParameters['id'];

  if (userId == null) {
    // Automatically returns status 400 to the client
    throw HttpResponseException.badRequest(
      message: 'The "id" parameter is required.',
      details: [
        {'field': 'id', 'issue': 'must not be empty'},
      ],
    );
  }

  if (userId != 'allowed-user') {
    // Automatically returns status 403 to the client
    throw HttpResponseException.forbidden(
      message: 'Access denied to the requested profile.',
    );
  }

  return Response.ok('User Profile Data');
}
```

### 4. Graceful Signal Termination

`serveHandler` uses `waitForTerminate` under the hood to listen for shutdown
signals (`SIGTERM` and `SIGINT`). SIGTERM is the standard signal sent by Google
Cloud Run and GKE when stopping or scaling down a container instance.

If you are customizing the server initialization, you can call
`waitForTerminate` manually:

<?code-excerpt "example/graceful_termination.dart (graceful-termination)"?>
```dart
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware())
      .addHandler((_) => Response.ok('Custom setup'));

  // Start the server manually
  final server = await shelf_io.serve(handler, '0.0.0.0', 8080);

  // Await a shutdown signal (SIGTERM or SIGINT)
  await waitForTerminate();

  // Gracefully shut down the server
  await server.close();
}
```

[issues]: https://github.com/googleapis/google-cloud-dart/issues
