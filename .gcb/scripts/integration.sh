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
summary="## Integration Test Results\n\n"

# Find all directories containing both pubspec.yaml and a test directory
while IFS= read -r -d '' pubspec_path; do
  dir=$(dirname "$pubspec_path")
  if [ -d "$dir/test" ]; then
    echo "==== Testing package in $dir ===="
    
    set +e
    (
      cd "$dir"
      dart pub get
      # Run tests, focusing on integration tests if they are separated, 
      # or just all tests.
      dart test
    )
    exit_code=$?
    set -e
    
    if [ $exit_code -eq 0 ]; then
      summary="$summary- ✅ \`$dir\` passed\n"
    else
      summary="$summary- ❌ \`$dir\` failed\n"
      failed=1
    fi
  fi
done < <(find . -name "pubspec.yaml" -print0)

echo "==== DONE ===="

# Post a comment back to the GitHub PR if the necessary environment variables are set.
if [ -n "$_PR_NUMBER" ] && [ -n "$REPO_FULL_NAME" ] && [ -n "$GITHUB_TOKEN" ]; then
  echo "Posting test results to PR #$_PR_NUMBER"
  export SUMMARY="$summary"
  
  dart run <(cat << 'EOF'
import 'dart:convert';
import 'dart:io';

void main() async {
  final summary = Platform.environment['SUMMARY']!;
  final token = Platform.environment['GITHUB_TOKEN']!;
  final repo = Platform.environment['REPO_FULL_NAME']!;
  final pr = Platform.environment['_PR_NUMBER']!;

  final uri = Uri.parse('https://api.github.com/repos/$repo/issues/$pr/comments');
  final request = await HttpClient().postUrl(uri)
    ..headers.add('Authorization', 'token $token')
    ..headers.add('Accept', 'application/vnd.github.v3+json')
    ..headers.add('User-Agent', 'Dart-Cloud-Build')
    ..write(jsonEncode({'body': summary}));

  final response = await request.close();
  print('GitHub API response: ${response.statusCode}');
  
  // Consume the response body to ensure the request is fully completed
  await response.drain();
}
EOF
)
fi

exit $failed
