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

# ============================================
# Marketplace Deployment Configuration
# ============================================
variable "goog_cm_deployment_name" {
  description = "Deployment name for the Data Commons Accelerator solution (used by GCP Marketplace for tracking and avoiding resource name collisions)"
  type        = string

  validation {
    condition     = length(var.goog_cm_deployment_name) >= 2 && length(var.goog_cm_deployment_name) <= 18
    error_message = "Deployment name must be between 2 and 18 characters (limited by GCP service account 30-char max: name + '-sa-' + 8-char suffix)."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,16}[a-z0-9]$", var.goog_cm_deployment_name))
    error_message = "Deployment name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number. Maximum 18 characters."
  }
}

# ============================================
# Project & Region Configuration
# ============================================
variable "project_id" {
  description = "GCP project ID where Data Commons Accelerator will be deployed"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "create_new_cluster" {
  description = "Create a new GKE Autopilot cluster with VPC networking. Set to false to use an existing cluster."
  type        = bool
  default     = true
}

variable "region" {
  description = "GCP region for new cluster and resources (e.g., us-central1). Only used when create_new_cluster is true."
  type        = string
  default     = "us-central1"

  validation {
    condition     = var.region == "" || can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "Region must be a valid GCP region (e.g., us-central1, europe-west3)."
  }
}

# ============================================
# GKE Cluster Configuration (Bring-Your-Own)
# ============================================
variable "gke_cluster_name" {
  description = "Name of an existing GKE cluster. Only used when create_new_cluster is false."
  type        = string
  default     = ""
}

variable "gke_cluster_location" {
  description = "Location (region or zone) of the existing GKE cluster. Only used when create_new_cluster is false."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace for Data Commons Accelerator deployment. Defaults to the deployment name (goog_cm_deployment_name) if not provided."
  type        = string
  default     = ""

  validation {
    condition     = var.namespace == "" || can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must consist of lowercase alphanumeric characters or '-', and must start and end with an alphanumeric character."
  }
}

variable "create_namespace" {
  description = "Create new Kubernetes namespace. Set to false if namespace already exists in the cluster."
  type        = bool
  default     = true
}

# ============================================
# Resource Name Overrides (Optional)
# ============================================
# These variables allow enterprise customers to specify exact resource names
# when they have naming conventions or pre-existing resources to integrate with.
# If not specified, resources use auto-generated names with random suffixes.

variable "cloudsql_instance_name_override" {
  description = "Override CloudSQL instance name (uses generated name with random suffix if not specified)"
  type        = string
  default     = ""

  validation {
    condition     = var.cloudsql_instance_name_override == "" || can(regex("^[a-z][a-z0-9-]{0,78}[a-z0-9]$", var.cloudsql_instance_name_override))
    error_message = "CloudSQL instance name must be lowercase, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "gcs_bucket_name_override" {
  description = "Override GCS bucket name (uses generated name with random suffix if not specified)"
  type        = string
  default     = ""

  validation {
    condition     = var.gcs_bucket_name_override == "" || can(regex("^[a-z0-9][a-z0-9-_.]{1,61}[a-z0-9]$", var.gcs_bucket_name_override))
    error_message = "Bucket name must be 3-63 characters, start and end with lowercase letter or number, and contain only lowercase letters, numbers, hyphens, underscores, and dots."
  }
}

variable "service_account_name_override" {
  description = "Override GCP service account name (uses generated name with random suffix if not specified)"
  type        = string
  default     = ""

  validation {
    condition     = var.service_account_name_override == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_name_override))
    error_message = "Service account name must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

# ============================================
# API Keys Configuration
# ============================================
variable "dc_api_key" {
  description = "Data Commons API key for accessing Data Commons APIs"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.dc_api_key) > 0
    error_message = "Data Commons API key cannot be empty."
  }
}

# ============================================
# Application Configuration
# ============================================
variable "app_replicas" {
  description = "Number of replicas for the Data Commons Accelerator application deployment"
  type        = number
  default     = 1

  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "Application replicas must be between 1 and 10."
  }
}

variable "resource_tier" {
  description = "Resource allocation tier controlling application pod resources and CloudSQL database sizing (small, medium, large)"
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["small", "medium", "large"], var.resource_tier)
    error_message = "Resource tier must be one of: small, medium, large."
  }
}

variable "enable_natural_language" {
  description = "Enable natural language query features"
  type        = bool
  default     = true
}

variable "enable_data_sync" {
  description = "Enable automatic synchronization of custom data from GCS bucket to CloudSQL database"
  type        = bool
  default     = true
}

variable "flask_env" {
  description = "Data Commons domain template (pre-built configurations for specific domains)"
  type        = string
  default     = "health"

  validation {
    condition     = contains(["health", "education", "energy"], var.flask_env)
    error_message = "Domain template must be one of: health, education, energy."
  }
}

# ============================================
# Container Image Variables (Marketplace-populated)
# ============================================
variable "cdc_services_image_repo" {
  description = "Container image repository for CDC Services (populated by GCP Marketplace)"
  type        = string
  default     = ""
}

variable "cdc_services_image_tag" {
  description = "Container image tag for CDC Services (populated by GCP Marketplace)"
  type        = string
  default     = ""
}

variable "data_image_repo" {
  description = "Container image repository for Data service (populated by GCP Marketplace)"
  type        = string
  default     = ""
}

variable "data_image_tag" {
  description = "Container image tag for Data service (populated by GCP Marketplace)"
  type        = string
  default     = ""
}

# ============================================
# Helm Chart Variables (Marketplace-populated)
# ============================================
variable "helm_chart_repo" {
  description = "Helm chart repository URL (populated by GCP Marketplace)"
  type        = string
  default     = ""
}

variable "helm_chart_name" {
  description = "Helm chart name (populated by GCP Marketplace)"
  type        = string
  default     = "datacommons"

  validation {
    condition     = length(var.helm_chart_name) > 0
    error_message = "Helm chart name cannot be empty."
  }
}

variable "helm_chart_version" {
  description = "Helm chart version (populated by GCP Marketplace)"
  type        = string
  default     = ""
}