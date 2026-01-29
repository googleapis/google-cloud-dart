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

/// Stores and retrieves potentially large, immutable data objects.
library;

export 'package:google_cloud_rpc/exceptions.dart';

export 'src/bucket_metadata.dart';
export 'src/client.dart';
export 'src/object_metadata.dart';
export 'src/project_team.dart';
export 'src/retry.dart' hide delaySequence;
