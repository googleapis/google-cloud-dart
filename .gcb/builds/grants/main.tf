# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "google_project" "project" {
}

# This service account is created externally. It is used for all the builds.
data "google_service_account" "integration-test-runner" {
  account_id = "integration-test-runner"
}

# The service account will need to bill requests to the project for Google
# Cloud Storage Requester Pays bucket operations.
resource "google_project_iam_member" "sa-can-use-service-usage" {
  project = data.google_project.project.id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${data.google_service_account.integration-test-runner.email}"
}

# The service account needs to access Vertex AI endpoints for Gemini tests.
resource "google_project_iam_member" "sa-can-use-vertex-ai" {
  project = data.google_project.project.id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${data.google_service_account.integration-test-runner.email}"
}

# The service account needs to create and delete logs for the logging tests.
resource "google_project_iam_member" "sa-can-use-logging" {
  project = data.google_project.project.id
  role    = "roles/logging.admin"
  member  = "serviceAccount:${data.google_service_account.integration-test-runner.email}"
}

output "runner" {
  value = data.google_service_account.integration-test-runner.id
}
