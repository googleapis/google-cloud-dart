## 0.1.0-wip

- Initial release of the experimental Google Cloud Pub/Sub client.
- Topic and subscription creation and deletion (`PubSub`, `Topic`,
  `Subscription`).
- Message publishing with configurable background batching and exponential
  backoff retries (`Topic.publish`, `PublishSettings`, `BatchingSettings`,
  `defaultRetry`).
- Synchronous (`Subscription.pull`) and resilient parallel streaming pull
  (`Subscription.streamingPull`) with automatic reconnection and backpressure
  handling.
- Message acknowledgment and ack deadline modification with configurable
  background batching (`Subscription.acknowledge`,
  `Subscription.modifyAckDeadline`, `AckSettings`) and streaming pull channel
  routing.
