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
# Variables
# ============================================
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the CloudSQL instance"
  type        = string
}

variable "instance_name" {
  description = "CloudSQL instance name (must be unique within project)"
  type        = string
}

variable "network_self_link" {
  description = "VPC network self link for private IP connection (from GKE cluster VPC)"
  type        = string
}

variable "allocated_ip_range" {
  description = "Name of the allocated IP range for Private Service Access (PSA)"
  type        = string
}

# ============================================
# Instance Configuration
# ============================================
variable "database_version" {
  description = "MySQL version (MYSQL_8_0, MYSQL_8_0_36, etc.)"
  type        = string
  default     = "MYSQL_8_0"
}

variable "tier" {
  description = "Machine tier (e.g., db-f1-micro, db-n1-standard-1, db-custom-2-7680)"
  type        = string
  default     = "db-n1-standard-1"
}

variable "zone" {
  description = "Primary zone for the CloudSQL instance"
  type        = string
  default     = null
}

variable "secondary_zone" {
  description = "Secondary zone for high availability (required if availability_type is REGIONAL)"
  type        = string
  default     = null
}

variable "availability_type" {
  description = "Availability type: ZONAL or REGIONAL (REGIONAL provides high availability)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Availability type must be either ZONAL or REGIONAL."
  }
}

# ============================================
# Storage Configuration
# ============================================
variable "disk_size" {
  description = "Disk size in GB (minimum 10 GB for MySQL)"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size >= 10
    error_message = "Disk size must be at least 10 GB for MySQL."
  }
}

variable "disk_type" {
  description = "Disk type: PD_SSD (recommended for production) or PD_HDD"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be either PD_SSD or PD_HDD."
  }
}

variable "disk_autoresize" {
  description = "Enable automatic disk size increase"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size in GB for autoresize (0 = unlimited)"
  type        = number
  default     = 0
}

# ============================================
# Backup Configuration
# ============================================
variable "backup_location" {
  description = "Backup location (defaults to instance region if not specified)"
  type        = string
  default     = null
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery (requires binary logging)"
  type        = bool
  default     = false
}

# ============================================
# Database and User Configuration
# ============================================
variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "datacommons"
}

variable "user_name" {
  description = "Name of the database user to create"
  type        = string
  default     = "datacommons"
}

# ============================================
# Security Configuration
# ============================================
variable "deletion_protection" {
  description = "Terraform deletion protection (prevents accidental terraform destroy)"
  type        = bool
  default     = false
}

variable "deletion_protection_enabled" {
  description = "GCP deletion protection (prevents deletion via console/API)"
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
