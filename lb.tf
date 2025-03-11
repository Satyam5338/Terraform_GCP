provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

resource "google_compute_network" "vpc" {
  name                    = "sp-vpc-2"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  private_ip_google_access = true
}

resource "google_compute_instance" "private_instance" {
  count        = 2
  name         = "private-instance-${count.index}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
  }
}

resource "google_compute_instance_group" "private_instance_group" {
  name        = "private-instance-group"
  zone        = "us-central1-a"
  instances   = google_compute_instance.private_instance[*].self_link
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "hc" {
  name = "instance-health-check"
  tcp_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "backend" {
  name          = "backend-service"
  health_checks = [google_compute_health_check.hc.id]

  backend {
    group = google_compute_instance_group.private_instance_group.self_link
  }
}

resource "google_compute_url_map" "lb_url_map" {
  name            = "url-map"
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.lb_url_map.id
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name       = "http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}
