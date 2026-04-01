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
# Provider Configurations
# ============================================

# Google Cloud provider
provider "google" {
  project = var.project_id
  region  = local.region
}

# Google Cloud Beta provider
provider "google-beta" {
  project = var.project_id
  region  = local.region
}

# Kubernetes provider - configured from cluster locals
provider "kubernetes" {
  host                   = "https://${local.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(local.cluster_ca_cert)
}

# Helm provider - configured from cluster locals
provider "helm" {
  kubernetes {
    host                   = "https://${local.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(local.cluster_ca_cert)
  }
}

# ============================================
# Data Sources
# ============================================
# Get current GCP client configuration for authentication
data "google_client_config" "default" {}

# Get current GCP project details
data "google_project" "current" {
  project_id = var.project_id
}

# ============================================
# GCP API Services
# ============================================

locals {
  # List of all required GCP APIs
  required_apis = toset([
    "cloudresourcemanager.googleapis.com", # Project-level resource management
    "compute.googleapis.com",              # VPC networking and compute resources
    "container.googleapis.com",            # GKE cluster management
    "sqladmin.googleapis.com",             # CloudSQL MySQL database
    "storage.googleapis.com",              # GCS bucket management
    "places-backend.googleapis.com",       # Maps API
    "maps-backend.googleapis.com",         # Maps API
    "apikeys.googleapis.com",              # Maps API key generation
    "serviceusage.googleapis.com",         # API usage and quotas monitoring
    "servicenetworking.googleapis.com",    # Private Service Access (CloudSQL)
    "iam.googleapis.com",                  # Service account and IAM management
  ])
}

resource "google_project_service" "apis" {
  for_each = local.required_apis

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  # Prevent race conditions during parallel API enablement
  timeouts {
    create = "30m"
    update = "30m"
  }
}

# ============================================
# Resource Naming Utilities
# ============================================

resource "random_id" "suffix" {
  byte_length = 4

  keepers = {
    project_id = var.project_id
  }
}

