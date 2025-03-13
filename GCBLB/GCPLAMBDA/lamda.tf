provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

resource "google_storage_bucket" "bucket" {
  name     = "sp-lamda-bucket"
  location = "US"
}

resource "google_service_account" "function_sa" {
  account_id   = "cloud-function-sa"
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "function_logging" {
  project = "sp-terra-project"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.function_sa.email}"
  ]
}

resource "google_cloudfunctions_function" "function" {
  name                  = "log-file-uploads"
  runtime               = "python311"
  region                = "us-central1"
  available_memory_mb   = 256
  service_account_email = google_service_account.function_sa.email
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point           = "log_upload"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.bucket.name
  }
}

resource "google_storage_bucket_object" "archive" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./function-source.zip"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
