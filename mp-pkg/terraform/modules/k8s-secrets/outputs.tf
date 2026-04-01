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
# Kubernetes Secrets Outputs
# ============================================

output "secret_names" {
  description = "Map of secret keys to their created names in Kubernetes"
  value       = { for k, v in kubernetes_secret_v1.secrets : k => v.metadata[0].name }
}

output "secret_namespaces" {
  description = "Map of secret keys to their namespaces"
  value       = { for k, v in kubernetes_secret_v1.secrets : k => v.metadata[0].namespace }
}

output "secret_ids" {
  description = "Map of secret keys to their full Kubernetes resource IDs (namespace/name)"
  value       = { for k, v in kubernetes_secret_v1.secrets : k => "${v.metadata[0].namespace}/${v.metadata[0].name}" }
}
