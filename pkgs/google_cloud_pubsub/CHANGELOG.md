## 0.1.0-wip

- Added resilient streaming pull in `Subscription.streamingPull` with support
  for parallel streams (`maxConcurrentStreams`), automatic reconnection with
  exponential backoff, and backpressure pause/resume forwarding.
- Routed background `Subscription.acknowledge` and `modifyAckDeadline` batches
  directly over active streaming pull channels.
- Added `BatchingSettings`, `PublishSettings`, and `AckSettings`.
  `BatchingSettings.maxBytes` is measured against the serialized request, the
  same way Pub/Sub enforces its own limits. Both it and
  `BatchingSettings.maxMessages` are capped to the limits that apply to the
  request being batched: 10,000,000 bytes and 1,000 messages for publishing,
  512,000 bytes for acknowledgments. `AckSettings` defaults `maxBytes` to
  512,000 bytes rather than sharing the larger publish-oriented default, which
  was twice what the server accepts for `Acknowledge` and `ModifyAckDeadline`.
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
