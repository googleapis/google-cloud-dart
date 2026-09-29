## 0.1.0-wip

- Added `BatchingSettings`, `PublishSettings`, and `AckSettings`.
  `BatchingSettings.maxBytes` is measured against the serialized request, the
  same way Pub/Sub enforces its own limits, and defaults to 512,000 bytes, which
  every request kind accepts. Asking for more than the server accepts for the
  request being batched throws an `ArgumentError`: 10,000,000 bytes and 1,000
  messages for publishing, 512,000 bytes for acknowledgments.
- Added background message batching for `Topic.publish`.
- Added background acknowledgment and deadline modification batching for
  `Subscription.acknowledge` and `Subscription.modifyAckDeadline`.
- Added `close()` lifecycle methods on `Topic` and `Subscription`.
- Re-exported `RetryRunner` and `ExponentialRetry` from
  `package:google_cloud_rpc` and added `defaultRetry` to configure exponential
  backoff retry parameters for Pub/Sub operations.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
