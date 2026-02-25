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
# Namespace
# ============================================
output "namespace" {
  description = "Kubernetes namespace where DataCommons is deployed"
  value       = local.namespace_name
}

# ============================================
# GCS Bucket
# ============================================
output "gcs_bucket_url" {
  description = "GCS bucket URL (gs://<bucket_name>)"
  value       = module.gcs_bucket.bucket_url
}

# ============================================
# Access Commands
# ============================================
output "kubectl_configure" {
  description = "Command to configure kubectl for your GKE cluster"
  value       = "gcloud container clusters get-credentials ${local.cluster_name} --location=${local.cluster_location} --project=${var.project_id}"
}

output "verify_pods" {
  description = "Command to verify Data Commons pods are running"
  value       = "kubectl get pods -n ${local.namespace_name}"
}

output "port_forward" {
  description = "Port-forward command to access Data Commons locally (with auto-retry)"
  value       = "until kubectl port-forward -n ${local.namespace_name} svc/datacommons 8080:8080; do echo 'Port-forward crashed. Respawning...' >&2; sleep 1; done"
}

output "cloud_shell_access" {
  description = "Cloud Shell quick access: GKE Console > cluster > Connect > Run in Cloud Shell, then run the port-forward command"
  value       = "GKE Console > ${local.cluster_name} > Connect > Run in Cloud Shell, then run: until kubectl port-forward -n ${local.namespace_name} svc/datacommons 8080:8080; do echo 'Respawning...' >&2; sleep 1; done — then click 'Web Preview' > 'Preview on port 8080'"
}

output "upload_data" {
  description = "Command to upload custom data to GCS bucket"
  value       = "gsutil cp -r /path/to/your/data gs://${module.gcs_bucket.bucket_name}/input"
}

output "view_logs" {
  description = "Command to view application logs"
  value       = "kubectl logs -n ${local.namespace_name} -l app=datacommons --tail=100 -f"
}

output "retrieve_admin_credentials" {
  description = "Commands to retrieve admin panel credentials (username and password)"
  value       = "echo 'Admin Username:' && kubectl get secret datacommons -n ${local.namespace_name} -o jsonpath='{.data.ADMIN_PANEL_USERNAME}' | base64 -d && echo && echo 'Admin Password:' && kubectl get secret datacommons -n ${local.namespace_name} -o jsonpath='{.data.ADMIN_PANEL_PASSWORD}' | base64 -d && echo"
}

