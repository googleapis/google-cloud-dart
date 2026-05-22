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

import 'dart:math';

const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String randomAlphaNumString(int length) => [
  for (int i = 0; i < length; i++) _chars[_random.nextInt(_chars.length)],
].join();
