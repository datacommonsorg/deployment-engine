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
# Local Values
# ============================================

locals {
  # ============================================
  # Common Labels
  # ============================================
  # Applied to all resources
  common_labels = {
    project  = "datacommons"
    solution = "datacommons-marketplace"
  }

  # ============================================
  # Resource Presets
  # ============================================
  # Pre-configured resource allocations for different deployment tiers
  # small:  Development/testing workloads
  # medium: Production workloads with moderate traffic
  # large:  Production workloads with high traffic
  resource_presets = {
    small = {
      memory        = "2Gi"
      cpu           = "1"
      replicas      = 1
      cloudsql_tier = "db-n1-standard-1"
      cloudsql_disk = 30
      cloudsql_ha   = false
    }
    medium = {
      memory        = "4Gi"
      cpu           = "2"
      replicas      = 2
      cloudsql_tier = "db-n1-standard-2"
      cloudsql_disk = 50
      cloudsql_ha   = false
    }
    large = {
      memory        = "8Gi"
      cpu           = "4"
      replicas      = 3
      cloudsql_tier = "db-n1-standard-4"
      cloudsql_disk = 100
      cloudsql_ha   = true
    }
  }

  # ============================================
  # Computed Values
  # ============================================
  region          = var.region
  cloudsql_region = local.region

  # Auto-derive GCS location from region
  # Maps region prefix to nearest GCS multi-region
  gcs_location = (
    startswith(local.region, "us-") || startswith(local.region, "northamerica-") ? "US" :
    startswith(local.region, "europe-") ? "EU" :
    startswith(local.region, "asia-") || startswith(local.region, "australia-") ? "ASIA" :
    "US" # Default fallback
  )

  # All tier-derived values accessed from resource_presets
  tier_preset               = local.resource_presets[var.resource_tier]
  cloudsql_tier             = local.tier_preset.cloudsql_tier
  cloudsql_ha_enabled       = local.tier_preset.cloudsql_ha
  cloudsql_availability_type = local.cloudsql_ha_enabled ? "REGIONAL" : "ZONAL"
  cloudsql_disk_size        = local.tier_preset.cloudsql_disk

  # Resource naming with deployment name for collision avoidance
  deployment_name = var.goog_cm_deployment_name
  resource_suffix = random_id.suffix.hex

  # ============================================
  # Resource Names (with override support)
  # ============================================
  # CloudSQL instance name - use override or computed with random suffix
  cloudsql_instance_name = var.cloudsql_instance_name_override != "" ? var.cloudsql_instance_name_override : "${local.deployment_name}-db-${local.resource_suffix}"

  # GCS bucket name - use override or computed with random suffix
  gcs_bucket_name_computed = "${local.deployment_name}-data-${local.resource_suffix}"
  gcs_bucket_name          = var.gcs_bucket_name_override != "" ? var.gcs_bucket_name_override : local.gcs_bucket_name_computed

  # Service account name - use override or computed with random suffix
  service_account_name = var.service_account_name_override != "" ? var.service_account_name_override : "${local.deployment_name}-sa-${local.resource_suffix}"

  # GKE node service account - only created for new clusters
  gke_node_sa_name = "${substr(local.deployment_name, 0, 14)}-gke-${local.resource_suffix}"

  # ============================================
  # Namespace Derivation
  # ============================================
  # Derive namespace from deployment name if not explicitly provided.
  # This prevents namespace collisions when users deploy the same solution twice.
  namespace = var.namespace != "" ? var.namespace : var.goog_cm_deployment_name

  # ============================================
  # Namespace Reference
  # ============================================
  namespace_name = kubernetes_namespace_v1.datacommons.metadata[0].name

  # ============================================
  # VPC Network
  # ============================================
  vpc_network_name      = google_compute_network.vpc.name
  vpc_network_self_link = google_compute_network.vpc.self_link

  # ============================================
  # Cluster Configuration
  # ============================================
  cluster_endpoint = google_container_cluster.autopilot.endpoint
  cluster_ca_cert  = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  cluster_name     = google_container_cluster.autopilot.name
  cluster_location = google_container_cluster.autopilot.location

  # ============================================
  # PSA Configuration
  # ============================================
  # PSA range prefix length: /20
  psa_range_prefix_length = 20

  # Use the created range for CloudSQL allocated_ip_range
  psa_range_name = google_compute_global_address.cloudsql_private_ip.name
}
