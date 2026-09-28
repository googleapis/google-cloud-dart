## 0.1.0-wip

- Added `BatchingSettings` and `PublishSettings`. `BatchingSettings.maxBytes` is
  measured against the serialized request, the same way Pub/Sub enforces its own
  limits. Asking for more than the server accepts for a `Publish` request
  (10,000,000 bytes and 1,000 messages) throws an `ArgumentError`.
- Added background message batching for `Topic.publish` and a `Topic.close()`
  lifecycle method.
- Added `publishMessages` on `PubSub` for publishing multiple messages in a
  single RPC.
- Re-exported `RetryRunner` and `ExponentialRetry` from
  `package:google_cloud_rpc` and added `defaultRetry` to configure exponential
  backoff retry parameters for Pub/Sub operations.
- Initial release of the experimental Google Cloud Pub/Sub client.
- Supports basic topic and subscription management.
- Supports publishing and pulling messages (including streaming pull).
