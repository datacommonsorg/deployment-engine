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
# Kubernetes Secrets Configuration
# ============================================
resource "kubernetes_namespace_v1" "datacommons" {
  metadata {
    name = local.namespace

    labels = merge(
      local.common_labels,
      {
        name = local.namespace
      }
    )
  }

  depends_on = [
    google_container_cluster.autopilot,
  ]
}

# ============================================
# Kubernetes Secrets
# ============================================

module "k8s_secrets" {
  source = "./modules/k8s-secrets"

  namespace = local.namespace_name

  secrets = {
    "datacommons-secrets" = {
      data = {
        # Database password from CloudSQL module
        DB_PASS = module.cloudsql.user_password

        # Google Maps API key from maps-api-keys module
        MAPS_API_KEY = module.maps_api_keys.api_key

        # DataCommons API key from user input
        DC_API_KEY = var.dc_api_key
      }
    }
  }

  labels = merge(
    local.common_labels,
    {
      component = "secrets"
    }
  )

  depends_on = [
    kubernetes_namespace_v1.datacommons,
    module.cloudsql,
    module.maps_api_keys
  ]
}
