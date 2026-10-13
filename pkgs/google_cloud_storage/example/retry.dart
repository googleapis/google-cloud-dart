// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// #docregion retry
import 'package:google_cloud_storage/google_cloud_storage.dart';

void main() async {
  // Retry idempotent operations at most twice.
  final storage = Storage(
    retry: const ExponentialRetry(retryIf: isTransientError, maxRetries: 2),
  );

  // This operation is only idempotent if `ifMetagenerationMatch` is provided,
  // so it is retried using the retry strategy passed to `Storage`.
  await storage.patchBucket(
    'my-bucket',
    BucketMetadataPatchBuilder()..labels = {'key': 'value'},
    ifMetagenerationMatch: BigInt.from(1),
  );

  // Without `ifGenerationMatch`, this operation isn't idempotent, so it's only
  // retried because `retry` is passed. That's safe if nothing else writes
  // this object.
  await storage.uploadObjectFromString(
    'my-bucket',
    'status.txt',
    'OK',
    retry: defaultRetry,
  );

  storage.close();
}

// #enddocregion retry
