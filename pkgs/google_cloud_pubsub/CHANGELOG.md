## 0.1.0-wip

- Added `BatchingSettings` and `PublishSettings`, and a `publishSettings`
  parameter on `PubSub.topic`, `PubSub.topicName`, `PubSub.createTopic` and the
  `Topic` constructors. `BatchingSettings.maxBytes` is measured against the
  serialized request, the same way Pub/Sub enforces its own limits, and
  defaults to 512,000 bytes. Creating a `Topic` whose settings exceed what the
  server accepts for a `Publish` request (10,000,000 bytes and 1,000 messages)
  throws an `ArgumentError`.
- `Topic.publish` now buffers messages, sends them in batches, and retries
  failed batches using `PublishSettings.retry`. A retried batch can publish a
  message more than once, which Pub/Sub's at-least-once delivery allows.
- Added `Topic.close()` and `Topic.isClosed`.
- Re-exported the retry API from `package:google_cloud_rpc` (`RetryRunner`,
  `ExponentialRetry`, `noRetry`, `hasStatusCode` and `Code`) and added
  `defaultRetry`, the default retry strategy for publishing. It follows the
  `Publish` retry policy in the Pub/Sub service configuration, as the client
  libraries for other languages do: it retries errors with the status codes
  `ABORTED`, `CANCELLED`, `DEADLINE_EXCEEDED`, `INTERNAL`,
  `RESOURCE_EXHAUSTED`, `UNAVAILABLE` and `UNKNOWN`, with a 100ms initial
  delay, a 4x multiplier, a 60s maximum delay, a 1 minute maximum retry
  interval and full jitter. Use `ExponentialRetry.onCodes` to retry other
  status codes.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
