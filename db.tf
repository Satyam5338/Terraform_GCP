provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

# Cloud SQL Instance (MySQL) with High Availability
resource "google_sql_database_instance" "mysql_instance" {
  name             = "mysql-instance"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier              = "db-n1-standard-1"
    availability_type = "REGIONAL"  # Enables automatic failover for high availability

    backup_configuration {
      enabled            = true
      start_time         = "23:00"
      location           = "us"
      binary_log_enabled = true
    }
  }

  deletion_protection = false
}

# Storage Bucket for Backups
resource "google_storage_bucket" "mysql_backup" {
  name          = "sp-mysql-bucket-01"
  location      = "US"
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  # Deletes backups older than 30 days
    }
  }
}

output "mysql_instance_connection_name" {
  value = google_sql_database_instance.mysql_instance.connection_name
}

output "backup_bucket_name" {
  value = google_storage_bucket.mysql_backup.name
}
