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

@TestOn('vm')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/pubsub_emulator_host_vm.dart';
import 'package:google_cloud_pubsub/src/version.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('packageVersion matches pubspec.yaml', () async {
    final pkgUri = await Isolate.resolvePackageUri(
      Uri.parse('package:google_cloud_pubsub/google_cloud_pubsub.dart'),
    );
    expect(pkgUri, isNotNull, reason: 'package URI must resolve');

    final pubspecFile = File.fromUri(pkgUri!.resolve('../pubspec.yaml'));
    expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml must exist');

    final content = pubspecFile.readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(content);
    expect(
      match,
      isNotNull,
      reason: 'version must be declared in pubspec.yaml',
    );

    final pubspecVersion = match!.group(1);
    expect(
      packageVersion,
      pubspecVersion,
      reason:
          'packageVersion in lib/src/version.dart ($packageVersion) must match '
          'version in pubspec.yaml ($pubspecVersion).',
    );
  });

  test('PubSub sends gl-dart and gccl tokens in x-goog-api-client', () async {
    final fakePublisher = FakePublisherClient();
    final fakeSubscriber = FakeSubscriberClient();
    final pubSub = PubSub.testing(
      projectId: 'test-project',
      channel: FakeClientChannel(),
      publisherClient: fakePublisher,
      subscriberClient: fakeSubscriber,
    );
    addTearDown(pubSub.close);

    final expectedHeader = 'gl-dart/$clientDartVersion gccl/$packageVersion';

    await pubSub.createTopic('projects/test-project/topics/t');
    expect(
      fakePublisher.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );

    await pubSub.publish('projects/test-project/topics/t', [1, 2, 3]);
    expect(
      fakePublisher.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );

    await pubSub.deleteTopic('projects/test-project/topics/t');
    expect(
      fakePublisher.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );

    await pubSub.createSubscription(
      'projects/test-project/subscriptions/s',
      topic: 'projects/test-project/topics/t',
    );
    expect(
      fakeSubscriber.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );

    await pubSub.acknowledge('projects/test-project/subscriptions/s', ['ack1']);
    expect(
      fakeSubscriber.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );

    await pubSub.modifyAckDeadline('projects/test-project/subscriptions/s', [
      'ack1',
    ], 30);
    expect(
      fakeSubscriber.lastOptions?.metadata['x-goog-api-client'],
      expectedHeader,
    );
  });
}
