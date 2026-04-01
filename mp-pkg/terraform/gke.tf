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
# GKE Node Service Account
# ============================================

resource "google_service_account" "gke_node" {
  provider = google

  account_id   = local.gke_node_sa_name
  display_name = "GKE Node SA (${local.deployment_name})"
  description  = "Service account for GKE node pools"
  project      = var.project_id

  depends_on = [google_project_service.apis["iam.googleapis.com"]]
}

resource "google_project_iam_member" "gke_node_default_sa" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_resource_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# ============================================
# GKE Cluster
# ============================================

resource "google_container_cluster" "autopilot" {
  provider = google-beta

  name     = "${local.deployment_name}-gke"
  location = local.region
  project  = var.project_id

  enable_autopilot = true

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.primary.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  release_channel {
    channel = "STABLE"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  deletion_protection = false

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke_node.email
    }
  }

  depends_on = [
    google_project_service.apis,
    google_compute_subnetwork.primary,
    google_project_iam_member.gke_node_default_sa,
    google_project_iam_member.gke_node_metric_writer,
    google_project_iam_member.gke_node_resource_metadata_writer,
  ]
}
