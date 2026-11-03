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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('isTransientError', () {
    test('retryable exceptions', () {
      expect(isTransientError(TooManyRequestsException('429')), isTrue);
      expect(isTransientError(InternalServerErrorException('500')), isTrue);
      expect(isTransientError(NotImplementedException('501')), isTrue);
      expect(isTransientError(BadGatewayException('502')), isTrue);
      expect(isTransientError(ServiceUnavailableException('503')), isTrue);
      expect(isTransientError(GatewayTimeoutException('504')), isTrue);
      expect(
        isTransientError(ServiceException('599', statusCode: 599)),
        isTrue,
      );
      expect(isTransientError(RequestTimeoutException('408')), isTrue);
      expect(isTransientError(http.ClientException('network')), isTrue);
      expect(
        isTransientError(ChecksumValidationException('bad checksum')),
        isTrue,
      );
    });

    test('non-retryable exceptions', () {
      expect(isTransientError(BadRequestException('400')), isFalse);
      expect(isTransientError(NotFoundException('404')), isFalse);
      expect(isTransientError(ConflictException('409')), isFalse);
      expect(isTransientError(CancelledException('499')), isFalse);
      expect(
        isTransientError(ServiceException('600', statusCode: 600)),
        isFalse,
      );
      expect(isTransientError(const FormatException('bad json')), isFalse);
    });

    test('does not retry errors', () {
      expect(isTransientError(StateError('bug')), isFalse);
    });
  });
}
