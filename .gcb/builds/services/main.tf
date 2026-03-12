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

variable "project" { type = string }

resource "google_project_service" "aiplatform" {
  project                    = var.project
  service                    = "aiplatform.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "generativelanguage" {
  project                    = var.project
  service                    = "generativelanguage.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudfunctions" {
  project                    = var.project
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "iam" {
  project                    = var.project
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "identitytoolkit" {
  project                    = var.project
  service                    = "identitytoolkit.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "language" {
  project                    = var.project
  service                    = "language.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "logging" {
  project                    = var.project
  service                    = "logging.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "secretmanager" {
  project                    = var.project
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "storage" {
  project                    = var.project
  service                    = "storage.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "translate" {
  project                    = var.project
  service                    = "translate.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudbuild" {
  project                    = var.project
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudscheduler" {
  project                    = var.project
  service                    = "cloudscheduler.googleapis.com"
  disable_dependent_services = true
}
