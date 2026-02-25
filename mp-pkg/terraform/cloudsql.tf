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
# Private Service Access (PSA) - Auto-Detection
# ============================================

# Query the Service Networking API to detect existing PSA connections on the VPC.
# Only active in BYO mode — in create mode, the new VPC has no existing PSA.
data "http" "psa_connections" {
  count = var.create_new_cluster ? 0 : 1

  url = "https://servicenetworking.googleapis.com/v1/services/servicenetworking.googleapis.com/connections?network=projects/${data.google_project.current.number}/global/networks/${local.vpc_network_name}"

  request_headers = {
    Authorization = "Bearer ${data.google_client_config.default.access_token}"
    Accept        = "application/json"
  }

  depends_on = [
    google_project_service.apis["servicenetworking.googleapis.com"],
  ]

  lifecycle {
    postcondition {
      # Accept 200 (success) as well as 403/404 (no access or no connections) — all are non-fatal.
      # Any of these statuses means we can safely fall through to the create path.
      condition     = contains([200, 403, 404], self.status_code)
      error_message = "Service Networking API returned unexpected status ${self.status_code}. Expected 200, 403, or 404."
    }
  }
}

# Allocate a /20 IP range for Private Service Access.
# Always created; in BYO mode existing ranges are preserved via concat below.
resource "google_compute_global_address" "cloudsql_private_ip" {
  count = local.create_psa_range ? 1 : 0

  provider = google

  name          = "${local.deployment_name}-psa-${local.resource_suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = local.psa_range_prefix_length
  network       = local.vpc_network_self_link
  project       = var.project_id

  labels = merge(
    local.common_labels,
    {
      component = "networking"
      purpose   = "cloudsql-psa"
    }
  )

  depends_on = [
    google_project_service.apis["compute.googleapis.com"],
    google_project_service.apis["servicenetworking.googleapis.com"],
  ]
}

# Create or update the Private Service Access connection.
# Always created; reserved_peering_ranges includes BOTH any existing ranges AND the new
# range to prevent destructive replacement of existing peering configuration.
resource "google_service_networking_connection" "cloudsql_private_vpc_connection" {
  count = local.create_psa_connection ? 1 : 0

  provider = google

  network = local.vpc_network_self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = distinct(concat(
    local.existing_psa_range_names,
    [google_compute_global_address.cloudsql_private_ip[0].name]
  ))

  # Prevent deletion of VPC peering connection before CloudSQL instance is removed
  deletion_policy = "ABANDON"

  # Handle case where connection already exists with different ranges
  update_on_creation_fail = true

  depends_on = [
    google_project_service.apis["compute.googleapis.com"],
    google_project_service.apis["servicenetworking.googleapis.com"],
    google_compute_global_address.cloudsql_private_ip[0],
  ]
}

# ============================================
# CloudSQL MySQL Instance
# ============================================

module "cloudsql" {
  source = "./modules/cloudsql"

  project_id         = var.project_id
  region             = local.cloudsql_region
  instance_name      = local.cloudsql_instance_name
  tier               = local.cloudsql_tier
  disk_size          = local.cloudsql_disk_size
  availability_type  = local.cloudsql_availability_type
  network_self_link  = local.vpc_network_self_link
  allocated_ip_range = local.psa_range_name
  database_name      = "datacommons"
  user_name          = "datacommons"

  labels = merge(
    local.common_labels,
    {
      component = "database"
      tier      = replace(local.cloudsql_tier, "db-", "")
    }
  )

  depends_on = [
    google_service_networking_connection.cloudsql_private_vpc_connection,
    data.http.psa_connections,
  ]
}