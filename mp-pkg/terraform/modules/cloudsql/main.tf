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
# CloudSQL MySQL Instance
# ============================================
resource "google_sql_database_instance" "instance" {
  project          = var.project_id
  name             = var.instance_name
  region           = var.region
  database_version = var.database_version

  settings {
    tier              = var.tier
    availability_type = var.availability_type

    # Storage configuration
    disk_size             = var.disk_size
    disk_type             = var.disk_type
    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      binary_log_enabled             = var.point_in_time_recovery_enabled
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # Network configuration - Private IP only
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_self_link
      ssl_mode                                      = "ENCRYPTED_ONLY"
      allocated_ip_range                            = var.allocated_ip_range
      enable_private_path_for_google_cloud_services = true
    }

    # Maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 3 # 3 AM
      update_track = "stable"
    }

    # Database flags (MySQL specific)
    database_flags {
      name  = "local_infile"
      value = "off"
    }

    # Query Insights
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # User labels
    user_labels = var.labels
  }

  deletion_protection = var.deletion_protection

  # Prevent disk size downgrade after autoresize
  lifecycle {
    ignore_changes = [
      settings[0].disk_size
    ]
  }
}

# ============================================
# Database Creation
# ============================================
resource "google_sql_database" "database" {
  project   = var.project_id
  instance  = google_sql_database_instance.instance.name
  name      = var.database_name
  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# ============================================
# Password Management
# ============================================
# Generate random password
resource "random_password" "db_password" {
  length  = 16
  special = true
  # Ensure password meets MySQL requirements
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

# Create database user with generated password
resource "google_sql_user" "user" {
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  name     = var.user_name
  host     = "%"
  password = random_password.db_password.result

  depends_on = [google_sql_database_instance.instance]
}
