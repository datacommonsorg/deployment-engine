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
  # Derive GCP region from cluster location.
  # In create mode: use var.region directly.
  # In BYO mode: derive from gke_cluster_location (strip zone suffix if present).
  # "europe-west3" → "europe-west3", "europe-west3-a" → "europe-west3"
  region          = var.create_new_cluster ? var.region : join("-", slice(split("-", var.gke_cluster_location), 0, 2))
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
  # Namespace Reference (conditional creation)
  # ============================================
  # Use created namespace or existing namespace based on create_namespace flag
  namespace_name = var.create_namespace ? kubernetes_namespace_v1.datacommons[0].metadata[0].name : data.kubernetes_namespace_v1.existing[0].metadata[0].name

  # ============================================
  # VPC Network (conditional: created vs. discovered)
  # ============================================
  # In create mode: use the new VPC created in vpc.tf.
  # In BYO mode: use the VPC discovered from the existing GKE cluster.
  vpc_network_name      = var.create_new_cluster ? google_compute_network.vpc[0].name : data.google_compute_network.vpc[0].name
  vpc_network_self_link = var.create_new_cluster ? google_compute_network.vpc[0].self_link : data.google_compute_network.vpc[0].self_link

  # ============================================
  # Cluster Configuration (dual-mode)
  # ============================================
  # In create mode: use the new Autopilot cluster created in gke.tf.
  # In BYO mode: use the existing cluster data source from main.tf.
  cluster_endpoint = var.create_new_cluster ? google_container_cluster.autopilot[0].endpoint : data.google_container_cluster.gke[0].endpoint
  cluster_ca_cert  = var.create_new_cluster ? google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate : data.google_container_cluster.gke[0].master_auth[0].cluster_ca_certificate
  cluster_name     = var.create_new_cluster ? google_container_cluster.autopilot[0].name : var.gke_cluster_name
  cluster_location = var.create_new_cluster ? google_container_cluster.autopilot[0].location : var.gke_cluster_location

  # ============================================
  # PSA Auto-Detection Configuration
  # ============================================
  # In create mode: always create new PSA (new VPC has no existing PSA).
  # In BYO mode: query the Service Networking API to detect existing connections.

  # Parse the HTTP response from the Service Networking API
  psa_api_response         = var.create_new_cluster ? {} : try(jsondecode(data.http.psa_connections[0].response_body), {})
  existing_psa_connections = try(local.psa_api_response.connections, [])
  psa_already_exists       = length(local.existing_psa_connections) > 0
  existing_psa_range_names = local.psa_already_exists ? local.existing_psa_connections[0].reservedPeeringRanges : []

  # Always create new PSA range and connection in both modes.
  # In BYO mode, reserved_peering_ranges (in cloudsql.tf) uses distinct(concat())
  # to preserve any existing ranges alongside the new one.
  # This eliminates the Terraform 1.5.7 plan-time count limitation entirely.
  create_psa_range      = true
  create_psa_connection = true

  # PSA range prefix length: /20 for all auto-created ranges
  psa_range_prefix_length = 20

  # Always use the newly created range for CloudSQL allocated_ip_range
  psa_range_name = google_compute_global_address.cloudsql_private_ip[0].name
}
