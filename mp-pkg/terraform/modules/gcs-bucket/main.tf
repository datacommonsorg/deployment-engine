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
# GCS Bucket Resource
# Creates the Cloud Storage bucket with security and lifecycle settings
# ============================================
resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = var.labels

  # Security: Uniform bucket-level access (replaces legacy object ACLs)
  # This enforces IAM-only access control, improving security posture
  uniform_bucket_level_access = true

  # Versioning: Protect against accidental overwrites and deletions
  # Conditionally enabled based on var.versioning_enabled
  dynamic "versioning" {
    for_each = var.versioning_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Encryption: Customer-managed encryption keys (CMEK) via Cloud KMS
  # If encryption_key_name is null, Google-managed keys are used automatically
  dynamic "encryption" {
    for_each = var.encryption_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.encryption_key_name
    }
  }

  # Lifecycle Rules: Automated object lifecycle management
  # Supports transitions, deletions, and versioning actions
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      # Action block: What to do with matching objects
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }

      # Condition block: When to apply this rule
      condition {
        age                        = lookup(lifecycle_rule.value.condition, "age", null)
        created_before             = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class      = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        matches_prefix             = lookup(lifecycle_rule.value.condition, "matches_prefix", null)
        matches_suffix             = lookup(lifecycle_rule.value.condition, "matches_suffix", null)
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        custom_time_before         = lookup(lifecycle_rule.value.condition, "custom_time_before", null)
        days_since_custom_time     = lookup(lifecycle_rule.value.condition, "days_since_custom_time", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
        noncurrent_time_before     = lookup(lifecycle_rule.value.condition, "noncurrent_time_before", null)
      }
    }
  }
}

# ============================================
# IAM Bindings
# Grant access to bucket using IAM roles
# Each member is bound independently for safe incremental additions
# ============================================
resource "google_storage_bucket_iam_member" "members" {
  for_each = {
    for idx, member in var.iam_members :
    "${member.role}-${member.member}" => member
  }

  bucket = google_storage_bucket.bucket.name
  role   = each.value.role
  member = each.value.member
}
