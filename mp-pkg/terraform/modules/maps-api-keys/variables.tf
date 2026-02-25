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
# API Keys Variables
# ============================================

# ============================================
# Required Variables
# ============================================
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for API key naming (e.g., 'datacommons-prod')"
  type        = string
}

# ============================================
# API Configuration
# ============================================
variable "api_targets" {
  description = "List of Google API services this key can access"
  type        = list(string)
  default = [
    "maps-backend.googleapis.com",
    "places-backend.googleapis.com"
  ]
}

# ============================================
# Application Restrictions
# ============================================
variable "allowed_referrers" {
  description = "List of allowed HTTP referrers for browser applications (e.g., ['https://example.com/*'])"
  type        = list(string)
  default     = []
}

variable "allowed_android_applications" {
  description = "List of allowed Android applications (package_name and sha1_fingerprint)"
  type = list(object({
    package_name     = string
    sha1_fingerprint = string
  }))
  default = []
}

variable "allowed_ios_bundle_ids" {
  description = "List of allowed iOS bundle IDs"
  type        = list(string)
  default     = []
}

# ============================================
# Labels
# ============================================
variable "labels" {
  description = "Resource labels/tags for organization and cost tracking"
  type        = map(string)
  default     = {}
}
