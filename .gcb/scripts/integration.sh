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

echo "==== Running Dart Integration Tests ===="

failed=0

cd packages/google_cloud_storage/
dart pub get

set +e
dart --define=http=proxy test/storage_test.dart >/tmp/test.output 2>&1
exit_code=$?
set -e

cd ../..

if [ $exit_code -ne 0 ]; then
  failed=1
fi

if [ -n "$_PR_NUMBER" ] && [ -n "$REPO_FULL_NAME" ] && [ -n "$GITHUB_TOKEN" ]; then
  echo "Posting test results to PR #$_PR_NUMBER"
  
  if ! command -v jq &> /dev/null; then
    apt-get update -y && apt-get install -y jq
  fi

  # Escape the test output into a JSON string
  json_payload=$(jq -Rs --arg prefix "## Integration Test Results\n\n\`\`\`text\n" --arg suffix "\n\`\`\`\n" '{body: ($prefix + . + $suffix)}' < /tmp/test.output)

  curl -s -S -X POST -H "Authorization: token $GITHUB_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       -H "User-Agent: Dart-Cloud-Build" \
       -d "$json_payload" \
       "https://api.github.com/repos/$REPO_FULL_NAME/issues/$_PR_NUMBER/comments"
fi

exit $failed
