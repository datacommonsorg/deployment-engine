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
# Kubernetes Secrets
# ============================================
variable "namespace" {
  description = "Kubernetes namespace where secrets will be created"
  type        = string
}

variable "secrets" {
  description = <<-EOT
    Map of secrets to create. Each secret can have:
    - data: Map of key-value pairs (values will be base64 encoded by Kubernetes)
    - labels: Optional additional labels for this specific secret

    Example:
    {
      "db-credentials" = {
        data = {
          DB_PASSWORD = "secret-value"
          DB_USER     = "myuser"
        }
        labels = {
          component = "database"
        }
      }
    }
  EOT
  type = map(object({
    data   = map(string)
    labels = optional(map(string), {})
  }))
}

# ============================================
# Optional Variables
# ============================================
variable "secret_type" {
  description = "Kubernetes secret type (Opaque, kubernetes.io/tls, etc.)"
  type        = string
  default     = "Opaque"

  validation {
    condition = contains([
      "Opaque",
      "kubernetes.io/service-account-token",
      "kubernetes.io/dockercfg",
      "kubernetes.io/dockerconfigjson",
      "kubernetes.io/basic-auth",
      "kubernetes.io/ssh-auth",
      "kubernetes.io/tls",
      "bootstrap.kubernetes.io/token"
    ], var.secret_type)
    error_message = "Secret type must be a valid Kubernetes secret type."
  }
}

variable "labels" {
  description = "Common labels to apply to all secrets"
  type        = map(string)
  default     = {}
}
