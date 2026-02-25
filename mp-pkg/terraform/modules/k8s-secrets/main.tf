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

resource "kubernetes_secret_v1" "secrets" {
  for_each = var.secrets

  metadata {
    name      = each.key
    namespace = var.namespace
    labels    = merge(var.labels, each.value.labels)
  }

  data = each.value.data
  type = var.secret_type
}
