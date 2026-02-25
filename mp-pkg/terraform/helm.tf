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
# Helm Release
# ============================================
resource "helm_release" "datacommons" {
  name       = "datacommons"
  repository = var.helm_chart_repo
  chart      = var.helm_chart_name
  version    = var.helm_chart_version
  namespace  = local.namespace_name

  wait          = true
  wait_for_jobs = true
  timeout       = 900

  # ============================================
  # Container Images (Marketplace-populated)
  # ============================================

  # CDC Services image
  set {
    name  = "deployment.image.repository"
    value = var.cdc_services_image_repo
  }

  set {
    name  = "deployment.image.tag"
    value = var.cdc_services_image_tag
  }

  # Data service image (db-init)
  set {
    name  = "dbInit.image.repository"
    value = var.data_image_repo
  }

  set {
    name  = "dbInit.image.tag"
    value = var.data_image_tag
  }

  # Data service image (db-sync)
  set {
    name  = "dbSync.image.repository"
    value = var.data_image_repo
  }

  set {
    name  = "dbSync.image.tag"
    value = var.data_image_tag
  }

  # ============================================
  # Application Configuration
  # ============================================

  set {
    name  = "deployment.replicas"
    value = local.tier_preset.replicas
  }

  set {
    name  = "config.enableNaturalLanguage"
    value = var.enable_natural_language
  }

  set {
    name  = "config.enableDataSync"
    value = var.enable_data_sync
  }

  set {
    name  = "config.flaskEnv"
    value = var.flask_env
  }

  set {
    name  = "dbInit.activeDeadlineSeconds"
    value = "900"
  }

  # ============================================
  # Resource Allocation
  # ============================================

  set {
    name  = "deployment.resources.limits.memory"
    value = local.tier_preset.memory
  }

  set {
    name  = "deployment.resources.limits.cpu"
    value = local.tier_preset.cpu
  }

  set {
    name  = "deployment.resources.requests.memory"
    value = local.tier_preset.memory
  }

  set {
    name  = "deployment.resources.requests.cpu"
    value = local.tier_preset.cpu
  }

  # ============================================
  # CloudSQL Configuration
  # ============================================

  set {
    name  = "config.cloudsql.enabled"
    value = "true"
  }

  set {
    name  = "config.cloudsql.instance"
    value = module.cloudsql.instance_connection_name
  }

  set {
    name  = "config.cloudsql.database"
    value = module.cloudsql.database_name
  }

  set {
    name  = "config.cloudsql.user"
    value = module.cloudsql.user_name
  }

  set {
    name  = "config.cloudsql.usePrivateIP"
    value = "true"
  }

  # ============================================
  # GCS Bucket Configuration
  # ============================================

  set {
    name  = "config.gcs.bucket"
    value = module.gcs_bucket.bucket_url
  }

  # ============================================
  # Workload Identity
  # ============================================

  set {
    name  = "serviceAccount.gcpServiceAccountEmail"
    value = google_service_account.datacommons_workload.email
  }

  set {
    name  = "serviceAccount.name"
    value = "datacommons-ksa"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.datacommons_workload.email
  }

  # ============================================
  # Secrets Configuration
  # ============================================

  # Use existing Kubernetes secret created by Terraform
  set {
    name  = "existingSecret"
    value = "datacommons-secrets"
  }

  depends_on = [
    kubernetes_namespace_v1.datacommons,
    data.kubernetes_namespace_v1.existing,
    module.cloudsql,
    module.gcs_bucket,
    module.maps_api_keys,
    module.k8s_secrets,
    google_service_account.datacommons_workload,
    google_project_iam_member.datacommons_cloudsql_client,
    google_storage_bucket_iam_member.datacommons_workload_storage_admin,
    google_storage_bucket_object.input_dir,
    google_storage_bucket_object.output_dir,
    google_service_account_iam_member.datacommons_workload_identity_user,
    google_service_networking_connection.cloudsql_private_vpc_connection,
    data.google_container_cluster.gke,
    data.google_compute_network.vpc,
    google_container_cluster.autopilot,
    google_compute_router_nat.nat,
  ]
}
