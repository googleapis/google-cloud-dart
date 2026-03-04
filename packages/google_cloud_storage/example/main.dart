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

import 'dart:convert';

import 'package:google_cloud_storage/google_cloud_storage.dart';

void main() async {
  // By default, the `Storage` class will use the currently configured project
  // and automatically attempt to authenticate using Application Default
  // Credentials.
  final storage = Storage();

  // Create a bucket.
  final bucket = await storage.createBucket(
    BucketMetadata(
      name: 'put-your-bucket-name-here',
      defaultObjectAcl: [
        ObjectAccessControl(entity: 'allUsers', role: 'READER'),
      ],
      website: BucketWebsiteConfiguration(mainPageSuffix: 'index.html'),
    ),
  );
  await storage.insertObject(
    bucket.name!,
    'index.html',
    utf8.encode('<h1>Hello World!</h1>'),
    metadata: ObjectMetadata(contentType: 'text/html'),
  );
  print('Your website is available at ${bucket.selfLink}');
  storage.close();
}
