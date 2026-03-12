#!/usr/bin/env bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

echo "==== Running Dart Integration Tests ===="

failed=0

# Find all directories containing both pubspec.yaml and a test directory
while IFS= read -r -d '' pubspec_path; do
  dir=$(dirname "$pubspec_path")
  if [ -d "$dir/test" ]; then
    echo "==== Testing package in $dir ===="
    
    set +e
    (
      cd "$dir"
      dart pub get
      # Run only integration tests using the 'integration' preset defined in dart_test.yaml
      dart test -P integration
    )
    exit_code=$?
    set -e
    
    if [ $exit_code -ne 0 ]; then
      failed=1
    fi
  fi
done < <(find . -name "pubspec.yaml" -print0)

echo "==== DONE ===="

exit $failed
