## 0.1.0-wip

- Preserved configured `publishSettings` and `ackSettings` when calling
  `Topic.create()` and `Subscription.create()`, returning `this`.
- Cleanly closed stream controller with `unawaited(controller.close())` on
  mid-stream gRPC errors in `PubSub.streamingPullWithStream` to prevent
  downstream consumers from hanging.
- Aligned default `maxMessages` in `PubSub.pull` to 100 to match
  `Subscription.pull`.
- Synchronously set `isCancelled = true` before stream cancellation in
  `Subscription.streamingPull` teardown on non-retryable errors or exhausted
  retries to prevent duplicate errors and orphaned reconnect timers.
- Harmonized error messages in `BatchingSettings` to 'Must be greater than
  zero'.

- Closed stream controller on setup failure in `PubSub.streamingPullWithStream`
  to prevent consumers from hanging.
- Added immediate no-op on empty collections for `PubSub.publishMessages`,
  `PubSub.acknowledge`, `PubSub.modifyAckDeadline`,
  `Subscription.acknowledgeNow`, and `Subscription.modifyAckDeadlineNow`.
- Added parameter validation for `PubSub.pull` and `Subscription.pull`
  (`maxMessages > 0`), `PubSub.streamingPull` (`streamAckDeadlineSeconds`),
  and `PubSub.modifyAckDeadline` (`ackDeadlineSeconds >= 0`).
- Inverted `Subscription.close()` teardown order to flush batchers over active
  streams before tearing down stream controllers.
- Calculated realistic item sizes for ACK and modify ack deadline batchers.
- Protected `Batcher._flush` against synchronous throws from `onBatch`.
- Made `Batcher`, `_AckRequest`, `_ModifyAckDeadlineRequest`, and
  `_PublishRequest` final classes.
- Included `BadGatewayException` and `RequestTimeoutException` in `isRetryable`.
- Implemented informative `toString()` on `Message` and `ReceivedMessage`.

- Added `@TestOn('vm')` platform annotations to all tests to skip browser runs.
- Removed invalid stream drain calls during streaming pull connection teardown.
- Failed attached completers with `completeError` when unary ACK or deadline
  modification fallback fails in `Subscription`.
- Verified `stream.hasListener` before buffering ACKs and deadline
  modifications into gRPC request controllers, falling back to unary RPCs.
- Prevented zombie reconnections on closed subscriptions and cancelled all
  active streaming pull controllers in `Subscription.close()`.
- Prevented async cancellation race in `PubSub.streamingPullWithStream` when
  canceled while awaiting call options.
- Cleaned up `StreamSubscription` and stopped `Stopwatch` on stream reconnects.
- Aligned error classification so `StatusCode.aborted` is retryable across
  raw `GrpcError` and mapped exceptions, while `StatusCode.dataLoss` is
  non-retryable across both.
- Clarified reconnection timeout in `Subscription.streamingPull`: omitting retry
  defaults to unlimited reconnection timeout (`totalTimeout: null`), while
  custom `RetrySettings` retain their configured `totalTimeout` (default 1
  minute) unless explicitly overridden.
- Replaced constructor assertions in `BatchingSettings` and `RetrySettings`
  with always-on parameter validation, and updated `PublishSettings` and
  `AckSettings` constructors to default to newly created instances.
- Documented asynchronous error emission on streaming methods and error
  conditions on `ReceivedMessage.acknowledge()` and `modifyAckDeadline()`.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
- Added exponential backoff retry support with randomized jitter.
- Named parameter `totalTimeout` in `RetrySettings` for maximum overall retry
  duration.
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
- Supported idle stream reconnection on healthy connections (>= 15s) and
  reconnection backoff delays on stream completion (`onDone`).
- Supported backpressure pause and resume forwarding on streaming pull.
- Protected multi-stream concurrency when individual parallel streams drop.
