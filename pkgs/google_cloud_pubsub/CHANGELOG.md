## 0.1.0-wip

- Added resilient streaming pull in `Subscription.streamingPull` with support
  for parallel streams (`maxConcurrentStreams`), automatic reconnection with
  exponential backoff, and backpressure pause/resume forwarding.
- Routed background `Subscription.acknowledge` and `modifyAckDeadline` batches
  directly over active streaming pull channels.
- Added `BatchingSettings`, `PublishSettings`, and `AckSettings`.
  `BatchingSettings.maxBytes` is measured against the serialized request, the
  same way Pub/Sub enforces its own limits. Asking for more than the server
  accepts for the request being batched throws an `ArgumentError`: 10,000,000
  bytes and 1,000 messages for publishing, 512,000 bytes for acknowledgments.
  `AckSettings` defaults `maxBytes` to 512,000 bytes rather than sharing the
  larger publish-oriented default, which was twice what the server accepts for
  `Acknowledge` and `ModifyAckDeadline`.
- Added background message batching for `Topic.publish`.
- Added background acknowledgment and deadline modification batching for
  `Subscription.acknowledge` and `Subscription.modifyAckDeadline`.
- Added `close()` lifecycle methods on `Topic` and `Subscription`.
- Added `publishMessages` on `PubSub` for publishing multiple messages in a
  single RPC.
- Re-exported `RetryRunner` and `ExponentialRetry` from `package:google_cloud_rpc`
  and added `defaultPubSubRetry` to configure exponential backoff retry
  parameters for publishing and acknowledgments.

- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
