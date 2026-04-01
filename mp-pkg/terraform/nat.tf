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
# Cloud Router + Cloud NAT
# ============================================

resource "google_compute_router" "nat_router" {
  provider = google

  name    = "${local.deployment_name}-router"
  region  = local.region
  network = google_compute_network.vpc.id
  project = var.project_id

  depends_on = [
    google_project_service.apis["compute.googleapis.com"]
  ]
}

resource "google_compute_router_nat" "nat" {
  provider = google

  name                               = "${local.deployment_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = local.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }

  depends_on = [
    google_compute_subnetwork.primary
  ]
}
