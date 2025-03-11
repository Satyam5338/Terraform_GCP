provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

# 1. Create a Storage Bucket
resource "google_storage_bucket" "my_bucket" {
  name          = "sp-buck-001"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"  # Move objects to Archive Storage (similar to AWS Glacier)
    }
    condition {
      age                   = 60  # Move objects to Archive after 60 days
      matches_storage_class = ["STANDARD", "NEARLINE", "COLDLINE"]
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365  # Delete objects after 365 days
    }
  }
}

# 2. Create a Service Account
resource "google_service_account" "compute_sa" {
  account_id   = "compute-instance-sa"
  display_name = "Compute Instance Service Account"
}

# 3. Grant Storage Read Permission to the Service Account
resource "google_storage_bucket_iam_member" "bucket_reader" {
  bucket = google_storage_bucket.my_bucket.name  # Reference the correct bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.compute_sa.email}"
}

# 4. Create a Compute Instance and Attach the Service Account
resource "google_compute_instance" "vm_instance" {
  name         = "my-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only"]  # Restrict to storage read access
  }
}
