## 0.1.0-wip

- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
- Added exponential backoff retry support with randomized jitter.
- Renamed `RetrySettings.maxRetryInterval` to `totalTimeout` (with deprecated
  getter and constructor parameter for backwards compatibility).
- Excluded deterministic errors including `ALREADY_EXISTS` (gRPC code 6 and
  `ConflictException`) from automatic retries.
- Made `PublishSettings` and `AckSettings` final classes.
- Added message batching for `Topic` publishing and `Subscription`
  acknowledgments / deadline modifications.
- Computed message byte size in `Topic` batching including attribute keys and
  values.
- Ensured completer safety in `Topic._onBatch` so all futures complete or fail
  exactly once even on mismatched server responses.
- Converted `Topic.close()` and `Subscription.close()` to async `Future<void>`
  flushing pending batches and awaiting in-flight operations.
- Throws `StateError` when publishing or acknowledging after `close()`.
- Wired `ReceivedMessage.acknowledge()` and `modifyAckDeadline()` on streaming
  pull, throwing `StateError` if no handler is configured.
- Filtered fatal/non-retryable errors in `streamingPull` to fail immediately.
- Supported idle stream reconnection on healthy connections (> 15s) and
  reconnection backoff delays on stream completion (`onDone`).
- Supported backpressure pause and resume forwarding on streaming pull.
- Protected multi-stream concurrency when individual parallel streams drop.
