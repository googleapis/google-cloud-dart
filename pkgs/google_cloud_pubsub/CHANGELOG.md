## 0.1.0-wip

- Added resilient streaming pull in `Subscription.streamingPull` with support
  for parallel streams (`maxConcurrentStreams`), automatic reconnection with
  exponential backoff, and backpressure pause/resume forwarding.
- Routed background `Subscription.acknowledge` and `modifyAckDeadline` batches
  directly over active streaming pull channels.
- Added `BatchingSettings`, `PublishSettings`, and `AckSettings`.
- Added background message batching for `Topic.publish`.
- Added background acknowledgment and deadline modification batching for
  `Subscription.acknowledge` and `Subscription.modifyAckDeadline`.
- Added `close()` lifecycle methods on `Topic` and `Subscription`.
- Added `publishMessages` on `PubSub` for publishing multiple messages in a
  single RPC.
- Added `RetrySettings` to configure exponential backoff retry parameters
  (delays, multiplier, jitter, and total timeout).
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
