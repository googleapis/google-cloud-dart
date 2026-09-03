## 0.1.0-wip

- Failed attached completers with `completeError` when unary ACK or deadline
  modification fallback fails in `Subscription`.
- Verified `stream.hasListener` before buffering ACKs and deadline
  modifications into gRPC request controllers, falling back to unary RPCs.
- Prevented zombie reconnections on closed subscriptions and cancelled all
  active streaming pull controllers in `Subscription.close()`.
- Prevented async cancellation race in `PubSub.streamingPullWithStream` when
  canceled while awaiting call options.
- Cleaned up `StreamSubscription` and stopped `Stopwatch` on stream reconnects.
- Aligned error classification so `StatusCode.aborted` is retryable across raw
  `GrpcError` and mapped exceptions, while `StatusCode.dataLoss` is non-retryable
  across both.
- Defaulted `totalTimeout` in custom `RetrySettings` passed to `streamingPull` to
  `null` (indefinite reconnection) unless explicitly specified.
- Added constructor assertions in `BatchingSettings` and `RetrySettings`.
- Documented asynchronous error emission on streaming methods and `StateError`
  on `ReceivedMessage.acknowledge()` and `modifyAckDeadline()`.
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
