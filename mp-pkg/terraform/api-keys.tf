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
# Google Maps API Keys
# ============================================
module "maps_api_keys" {
  source = "./modules/maps-api-keys"

  project_id  = var.project_id
  name_prefix = "${local.deployment_name}-maps"
  api_targets = [
    "maps-backend.googleapis.com",
    "places-backend.googleapis.com"
  ]

  labels = merge(
    local.common_labels,
    {
      component = "api-keys"
      purpose   = "maps-integration"
    }
  )

  depends_on = [google_project_service.apis["apikeys.googleapis.com"]]
}
