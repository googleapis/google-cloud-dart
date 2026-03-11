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

variable "project" {}
variable "region" {}
variable "service_account" {}

locals {
  gcb_app_installation_id = 1168573
  gcb_secret_name         = "projects/${var.project}/secrets/GitHub-github-oauthtoken-da481a/versions/latest"

  common_builds = {
    integration = {
      config = "integration.yaml"
    }
  }

  pr_builds = local.common_builds
  pm_builds = local.common_builds
}

data "google_project" "project" {
}



resource "google_cloudbuildv2_connection" "github" {
  project  = var.project
  location = var.region
  name     = "github"

  github_config {
    app_installation_id = local.gcb_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = local.gcb_secret_name
    }
  }
}

resource "google_cloudbuildv2_repository" "main" {
  project           = var.project
  location          = var.region
  name              = "googleapis-google-cloud-dart"
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = "https://github.com/googleapis/google-cloud-dart.git"
}

resource "google_cloudbuild_trigger" "pull-request" {
  for_each = tomap(local.pr_builds)
  location = var.region
  name     = "gcb-pr-${each.key}"
  filename = ".gcb/${each.value.config}"
  tags     = ["pull-request", "name:${each.key}"]

  service_account = var.service_account

  repository_event_config {
    repository = google_cloudbuildv2_repository.main.id
    pull_request {
      branch          = "^main$"
      comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
    }
  }

  substitutions = {
    _SCRIPT = lookup(each.value, "script", "")
  }
}

resource "google_cloudbuild_trigger" "post-merge" {
  for_each = {
    for k, v in local.pm_builds : k => {
      config         = v.config,
      script         = try(v.script, "")
      included_files = try(v.included_files, [])
    }
  }
  location       = var.region
  name           = "gcb-pm-${each.key}"
  filename       = ".gcb/${each.value.config}"
  tags           = ["post-merge", "push", "name:${each.key}"]
  included_files = each.value.included_files

  service_account = var.service_account

  repository_event_config {
    repository = google_cloudbuildv2_repository.main.id
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    _SCRIPT = lookup(each.value, "script", "")
  }
}


