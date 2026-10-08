## 0.1.0-wip

- Added `BatchingSettings` and `PublishSettings`, and a `publishSettings`
  parameter on `PubSub.topic`, `PubSub.topicName`, `PubSub.createTopic` and the
  `Topic` constructors. `BatchingSettings.maxBytes` is measured against the
  serialized request, the same way Pub/Sub enforces its own limits, and
  defaults to 512,000 bytes. Creating a `Topic` whose settings exceed what the
  server accepts for a `Publish` request (10,000,000 bytes and 1,000 messages)
  throws an `ArgumentError`.
- `Topic.publish` now buffers messages, sends them in batches, and retries
  failed batches using `PublishSettings.retry`.
- Added `Topic.close()` and `Topic.isClosed`.
- Re-exported `RetryRunner` and `ExponentialRetry` from
  `package:google_cloud_rpc` and added `defaultRetry` to configure exponential
  backoff retry parameters for Pub/Sub operations.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
