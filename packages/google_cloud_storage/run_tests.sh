#!/bin/bash
set -e
export GOOGLE_CLOUD_PROJECT=skilful-orb-203421

echo "Running test/patch_object_test.dart"
dart --define=http=record test/patch_object_test.dart

echo "Running test/object_metadata_api_test.dart"
dart --define=http=record test/object_metadata_api_test.dart

echo "Running test/bucket_metadata_api_test.dart"
dart --define=http=record test/bucket_metadata_api_test.dart

echo "Running test/bucket_metadata_json_test.dart"
dart --define=http=record test/bucket_metadata_json_test.dart

echo "Running test/bucket_metadata_test.dart"
dart --define=http=record test/bucket_metadata_test.dart

echo "Running test/common_json_test.dart"
dart --define=http=record test/common_json_test.dart

echo "Running test/crc32c_test.dart"
dart --define=http=record test/crc32c_test.dart

echo "Running test/create_bucket_test.dart"
dart --define=http=record test/create_bucket_test.dart

echo "Running test/delete_bucket_test.dart"
dart --define=http=record test/delete_bucket_test.dart

echo "Running test/delete_object_test.dart"
dart --define=http=record test/delete_object_test.dart

echo "Running test/download_object_test.dart"
dart --define=http=record test/download_object_test.dart

echo "Running test/insert_object_test.dart"
dart --define=http=record test/insert_object_test.dart

echo "Running test/list_buckets_test.dart"
dart --define=http=record test/list_buckets_test.dart

echo "Running test/list_objects_test.dart"
dart --define=http=record test/list_objects_test.dart

echo "Running test/object_metadata_json_test.dart"
dart --define=http=record test/object_metadata_json_test.dart

echo "Running test/object_metadata_test.dart"
dart --define=http=record test/object_metadata_test.dart

echo "Running test/patch_bucket_test.dart"
dart --define=http=record test/patch_bucket_test.dart

echo "Running test/project_team_test.dart"
dart --define=http=record test/project_team_test.dart

echo "Running test/retry_test.dart"
dart --define=http=record test/retry_test.dart
