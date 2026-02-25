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
# API Keys Outputs
# ============================================

output "api_key_id" {
  description = "The unique identifier of the API key resource"
  value       = google_apikeys_key.maps_key.id
}

output "api_key_name" {
  description = "The resource name of the API key"
  value       = google_apikeys_key.maps_key.name
}

output "api_key_uid" {
  description = "The unique ID assigned to the API key by Google"
  value       = google_apikeys_key.maps_key.uid
}

output "api_key" {
  description = "The actual API key value"
  value       = google_apikeys_key.maps_key.key_string
  sensitive   = true
}

# ============================================
# Kubernetes Secret Data
# ============================================
output "k8s_secret_data" {
  description = "Secret data for Kubernetes Secret resource"
  value = {
    MAPS_API_KEY = google_apikeys_key.maps_key.key_string
  }
  sensitive = true
}
