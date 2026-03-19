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

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:google_cloud_storage/src/crc32c.dart';

class Crc32CBenchmark extends BenchmarkBase {
  final int size;
  final int count;
  late Uint8List data;

  Crc32CBenchmark(this.size, this.count)
    : super('Crc32CBenchmark: $size bytes × $count');

  @override
  void setup() {
    data = Uint8List(size);
    for (var i = 0; i < data.length; i++) {
      data[i] = i % 256;
    }
  }

  @override
  void run() {
    for (var i = 0; i < count; ++i) {
      Crc32c()
        ..update(data)
        ..toBase64();
    }
  }
}

void main() {
  Crc32CBenchmark(1024, 1).report();
  Crc32CBenchmark(1024 * 1024, 1).report();
  Crc32CBenchmark(1024, 1024).report();
  Crc32CBenchmark(10 * 1024 * 1024, 1).report();
}
