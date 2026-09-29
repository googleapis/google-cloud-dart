## 0.1.0-wip

- Added `BatchingSettings`, `PublishSettings`, and `AckSettings`, and a
  `publishSettings` parameter on `PubSub.topic`, `PubSub.topicName`,
  `PubSub.createTopic` and the `Topic` constructors, and an `ackSettings`
  parameter on `PubSub.subscription`, `PubSub.subscriptionName`,
  `PubSub.createSubscription` and the `Subscription` constructors.
  `BatchingSettings.maxBytes` is measured against the serialized request, the
  same way Pub/Sub enforces its own limits, and defaults to 512,000 bytes, which
  every request kind accepts. Creating a `Topic` or `Subscription` whose
  settings exceed what the server accepts for the request being batched throws
  an `ArgumentError`: 10,000,000 bytes and 1,000 messages for publishing,
  512,000 bytes for acknowledgments.
- `Topic.publish` now buffers messages, sends them in batches, and retries
  failed batches using `PublishSettings.retry`.
- Added background acknowledgment and deadline modification batching for
  `Subscription.acknowledge` and `Subscription.modifyAckDeadline`.
- Added `close()` and `isClosed` on `Topic` and `Subscription`.
- Re-exported `RetryRunner` and `ExponentialRetry` from
  `package:google_cloud_rpc` and added `defaultRetry` to configure exponential
  backoff retry parameters for Pub/Sub operations.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
