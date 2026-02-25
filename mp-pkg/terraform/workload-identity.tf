# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ============================================
# Workload Identity Configuration
# ============================================

# ============================================
# GCP Service Account for DataCommons Workload
# ============================================
resource "google_service_account" "datacommons_workload" {
  provider = google

  account_id   = local.service_account_name
  display_name = "DataCommons Workload Service Account (${local.deployment_name})"
  description  = "Service account for DataCommons application running on GKE with Workload Identity"
  project      = var.project_id

  depends_on = [google_project_service.apis["iam.googleapis.com"]]
}

# ============================================
# IAM Role Bindings - Project Level
# ============================================

# CloudSQL Client - Required for CloudSQL access via Cloud SQL Auth Proxy or private IP
resource "google_project_iam_member" "datacommons_cloudsql_client" {
  provider = google

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.datacommons_workload.email}"

  depends_on = [google_service_account.datacommons_workload]
}

# NOTE: Storage Object Admin IAM is granted at the bucket level (not project level)

# ============================================
# Workload Identity Binding
# ============================================

resource "google_service_account_iam_member" "datacommons_workload_identity_user" {
  provider = google

  service_account_id = google_service_account.datacommons_workload.name
  role               = "roles/iam.workloadIdentityUser"

  # Member format: serviceAccount:{PROJECT_ID}.svc.id.goog[{NAMESPACE}/{KSA_NAME}]
  member = "serviceAccount:${var.project_id}.svc.id.goog[${local.namespace_name}/datacommons-ksa]"

  depends_on = [google_service_account.datacommons_workload]
}
