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
# Outputs
# ============================================

# ============================================
# Instance Information
# ============================================
output "instance_name" {
  description = "CloudSQL instance name"
  value       = google_sql_database_instance.instance.name
}

output "instance_connection_name" {
  description = "CloudSQL instance connection name (project:region:instance) for Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.instance.connection_name
}

output "instance_self_link" {
  description = "CloudSQL instance self link"
  value       = google_sql_database_instance.instance.self_link
}

output "instance_service_account_email" {
  description = "CloudSQL instance service account email"
  value       = google_sql_database_instance.instance.service_account_email_address
}

# ============================================
# Network Information
# ============================================
output "private_ip_address" {
  description = "Private IP address for direct connection from GKE (within VPC)"
  value       = google_sql_database_instance.instance.private_ip_address
}

# ============================================
# Database Information
# ============================================
output "database_name" {
  description = "Name of the created database"
  value       = var.database_name
}

# ============================================
# User Credentials
# ============================================
output "user_name" {
  description = "Database user name"
  value       = var.user_name
}

output "user_password" {
  description = "Database user password (auto-generated)"
  value       = random_password.db_password.result
  sensitive   = true
}

# ============================================
# Connection Information
# ============================================
output "connection_string" {
  description = "MySQL connection string for direct private IP connection"
  value       = "mysql://${var.user_name}@${google_sql_database_instance.instance.private_ip_address}:3306/${var.database_name}"
  sensitive   = true
}

output "jdbc_connection_string" {
  description = "JDBC connection string for applications"
  value       = "jdbc:mysql://${google_sql_database_instance.instance.private_ip_address}:3306/${var.database_name}?useSSL=true&requireSSL=true"
}

# ============================================
# Kubernetes Configuration
# ============================================
output "k8s_env_vars" {
  description = "Environment variables for Kubernetes deployments"
  value = {
    CLOUDSQL_INSTANCE = google_sql_database_instance.instance.connection_name
    DB_HOST           = google_sql_database_instance.instance.private_ip_address
    DB_PORT           = "3306"
    DB_NAME           = var.database_name
    DB_USER           = var.user_name
    USE_CLOUDSQL      = "true"
  }
}

output "k8s_secret_data" {
  description = "Secret data for Kubernetes Secret resource (use with k8s-secrets module)"
  value = {
    DB_PASSWORD = random_password.db_password.result
  }
  sensitive = true
}
