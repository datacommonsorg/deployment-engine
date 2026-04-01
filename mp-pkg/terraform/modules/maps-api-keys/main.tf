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
# API Keys
# ============================================

# Random suffix for unique naming
resource "random_id" "key_suffix" {
  byte_length = 4
}

# ============================================
# Google Maps API Key
# ============================================
resource "google_apikeys_key" "maps_key" {
  project      = var.project_id
  name         = "${var.name_prefix}-key-${random_id.key_suffix.hex}"
  display_name = "${var.name_prefix} Maps API Key"

  restrictions {
    dynamic "api_targets" {
      for_each = var.api_targets
      content {
        service = api_targets.value
      }
    }

    # Optional browser key restrictions
    dynamic "browser_key_restrictions" {
      for_each = length(var.allowed_referrers) > 0 ? [1] : []
      content {
        allowed_referrers = var.allowed_referrers
      }
    }

    # Optional Android app restrictions
    dynamic "android_key_restrictions" {
      for_each = length(var.allowed_android_applications) > 0 ? [1] : []
      content {
        dynamic "allowed_applications" {
          for_each = var.allowed_android_applications
          content {
            package_name     = allowed_applications.value.package_name
            sha1_fingerprint = allowed_applications.value.sha1_fingerprint
          }
        }
      }
    }

    # Optional iOS app restrictions
    dynamic "ios_key_restrictions" {
      for_each = length(var.allowed_ios_bundle_ids) > 0 ? [1] : []
      content {
        allowed_bundle_ids = var.allowed_ios_bundle_ids
      }
    }
  }
}
