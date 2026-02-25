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
# DataCommons GCS Bucket Module Variables
# ============================================

# ============================================
# Required Variables
# ============================================
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket (must be globally unique)"
  type        = string
}

# ============================================
# Location Configuration
# ============================================
variable "location" {
  description = "Bucket location (e.g., US, EU, ASIA, or specific region like us-central1)"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class: STANDARD, NEARLINE, COLDLINE, or ARCHIVE"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }
}

# ============================================
# Versioning Configuration
# ============================================
variable "versioning_enabled" {
  description = "Enable object versioning (recommended for data protection)"
  type        = bool
  default     = true
}

# ============================================
# Lifecycle Rules
# ============================================
variable "lifecycle_rules" {
  description = "Lifecycle rules for object management (passed directly to underlying module)"
  type        = any
  default     = []
}

# ============================================
# IAM Configuration
# ============================================
variable "iam_members" {
  description = "IAM members and their roles for bucket access"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

# ============================================
# Encryption Configuration
# ============================================
variable "encryption_key_name" {
  description = "Cloud KMS key name for customer-managed encryption (optional, uses Google-managed keys by default)"
  type        = string
  default     = null
}

# ============================================
# Deletion Protection
# ============================================
variable "force_destroy" {
  description = "Allow bucket deletion even if it contains objects (use with caution)"
  type        = bool
  default     = false
}

# ============================================
# Labels
# ============================================
variable "labels" {
  description = "Resource labels/tags for organization and cost tracking"
  type        = map(string)
  default     = {}
}
