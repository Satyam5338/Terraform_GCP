provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

# 1. Enable Cloud Logging and Monitoring APIs
resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

# 2. Create a Log-Based Metric to Track HTTP Requests
resource "google_logging_metric" "http_requests" {
  name   = "http_request_count"
  filter = "resource.type=\"gce_instance\" AND jsonPayload.method=\"GET\""  # Track only GET requests
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# 3. Create a Pub/Sub Topic for Notifications
resource "google_pubsub_topic" "alert_topic" {
  name = "http-alert-topic"
}

# 4. Create a Pub/Sub Subscription
resource "google_pubsub_subscription" "alert_subscription" {
  name  = "http-alert-subscription"
  topic = google_pubsub_topic.alert_topic.name
}

# 5. Create a Notification Channel (Email)
resource "google_monitoring_notification_channel" "email_alert" {
  display_name = "Email Alert"
  type         = "email"
  labels = {
    email_address = "satyam26patil@gmail.com"  # Replace with your email
  }
}

# 6. Create an Alert Policy
resource "google_monitoring_alert_policy" "high_http_requests" {
  display_name = "High HTTP Request Alert"
  combiner     = "OR"  # Required argument (Choose: OR, AND, AND_WITH_MATCHING_RESOURCE)
  notification_channels = [google_monitoring_notification_channel.email_alert.id]

  conditions {
    display_name = "HTTP Requests Threshold"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/http_request_count\" AND resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5  # Alert if requests exceed 5
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}
