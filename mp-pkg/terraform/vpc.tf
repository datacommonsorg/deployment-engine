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
# VPC Network
# ============================================

resource "google_compute_network" "vpc" {
  count = var.create_new_cluster ? 1 : 0

  provider = google

  name                    = "${local.deployment_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id

  depends_on = [
    google_project_service.apis["compute.googleapis.com"]
  ]
}

# ============================================
# Primary Subnet with GKE Secondary Ranges
# ============================================

resource "google_compute_subnetwork" "primary" {
  count = var.create_new_cluster ? 1 : 0

  provider = google

  name                     = "${local.deployment_name}-subnet"
  network                  = google_compute_network.vpc[0].id
  region                   = local.region
  ip_cidr_range            = "10.0.0.0/20"
  private_ip_google_access = true
  project                  = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/17"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/22"
  }

  log_config {
    aggregation_interval = "INTERVAL_30_SEC"
    flow_sampling        = 0.5
  }

  depends_on = [
    google_project_service.apis["compute.googleapis.com"]
  ]
}
