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
# GCS Bucket for DataCommons Data
# ============================================
module "gcs_bucket" {
  source = "./modules/gcs-bucket"

  project_id      = var.project_id
  bucket_name     = local.gcs_bucket_name
  location        = local.gcs_location
  storage_class   = "STANDARD"
  force_destroy   = true
  lifecycle_rules = []

  # IAM Members - empty during plan to avoid for_each dependency issues
  # IAM will be granted separately via google_storage_bucket_iam_member
  iam_members = []

  labels = merge(
    local.common_labels,
    {
      component = "storage"
      purpose   = "datacommons-data"
    }
  )

  depends_on = [google_project_service.apis["storage.googleapis.com"]]
}

# Grant workload service account access to the bucket
# Using separate resource to avoid for_each dependency issue during plan
resource "google_storage_bucket_iam_member" "datacommons_workload_storage_admin" {
  bucket = module.gcs_bucket.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.datacommons_workload.email}"

  depends_on = [
    module.gcs_bucket,
    google_service_account.datacommons_workload
  ]
}

# Create default directory structure required by DataCommons application
resource "google_storage_bucket_object" "input_dir" {
  bucket  = module.gcs_bucket.bucket_name
  name    = "input/"
  content = " "

  depends_on = [module.gcs_bucket]
}

resource "google_storage_bucket_object" "output_dir" {
  bucket  = module.gcs_bucket.bucket_name
  name    = "output/"
  content = " "

  depends_on = [module.gcs_bucket]
}
