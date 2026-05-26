`package:google_cloud_logging` provides a single class `StructuredLogger`.

`StructuredLogger` consumes logging events (e.g. from `package:logging`) and
outputs them to `stdout` using the Google Cloud structured logging format.

For example:

```dart
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logging/logging.dart';

void main() {
  // XXX make sure that listen doesn't mess with zones.
  Logger.root.onRecord.listen(const StructuredLogger().handleLogRecord);
  Logger.root.level = Level.ALL;

  Logger('MyLogger').warning('Out of disk space.');
  Logger('MyLogger').info({'cpu': 23, 'memory': '25G'});
}
```

would output:

```json
{
  "severity": "WARNING",
  "loggerName": "MyLogger",
  "message": "Out of disk space."
}
{
  "severity": "INFO",
  "loggerName": "MyLogger",
  "cpu": 23,
  "memory": "25G"
}
```

The output is captured by a logging agent, converted into a
[`LogEntry`](https://docs.cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry)
and then stored using [Cloud Logging](https://cloud.google.com/logging).

`package:google_cloud_logging` also looks at the Zone variable `'traceparent'`,
which can be set to the value of the
[`'traceparent'`](https://www.w3.org/TR/trace-context/) HTTP header of the
current request. If `'traceparent'` is set, then its information is added to
the structured log in order to allow log entries to be correlated with the
request that generated them.

For example, if the `'traceparent'` header value is
`00-06796866738c859f2f19b7cfb3214824-000000000000004a-00`:

```dart
    Zone.current
        .fork(
          zoneValues: {
            'traceparent': request.headers['traceparent'],
          },
        )
        .runGuarded(() async {
          Logger('MyLogger').warning('Out of disk space.');
        });
```

would output:

```json
{
  "severity": "WARNING",
  "loggerName": "MyLogger",
  "logging.googleapis.com/spanId": "000000000000004a",
  "logging.googleapis.com/trace": "06796866738c859f2f19b7cfb3214824",
  "logging.googleapis.com/trace_sampled": false,
  "message": "Out of disk space."
}
```

This allows `package:google_cloud_shelf` (and potentially other packages) to
provide tracing context without interacting directly with the logging system.

`package:google_cloud_logging` also provides some incidental functionality to
allow other packages to write structured logs:

- `formatTraceparent`: generates the appropriate json entries from a `'traceparent'` header.
- `sanitize`: converts a Dart object into a form that can be safely JSON serialized.
