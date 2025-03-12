provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

resource "google_compute_network" "vpc1" {
  name                    = "spatil-vpc-1"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet1" {
  name          = "subnet-1"
  network       = google_compute_network.vpc1.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

resource "google_compute_network" "vpc2" {
  name                    = "spatil-vpc-2"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet2" {
  name          = "subnet-2"
  network       = google_compute_network.vpc2.id
  ip_cidr_range = "10.2.0.0/16"
  region        = "asia-south1"
}

resource "google_compute_network_peering" "peering1" {
  name         = "vpc1-to-vpc2"
  network      = google_compute_network.vpc1.id
  peer_network = google_compute_network.vpc2.id
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "peering2" {
  name         = "vpc2-to-vpc1"
  network      = google_compute_network.vpc2.id
  peer_network = google_compute_network.vpc1.id
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_firewall" "allow_vpc1_to_vpc2" {
  name    = "allow-vpc1-to-vpc2"
  network = google_compute_network.vpc1.name

  allow {
    protocol = "all"
  }

  source_ranges = ["10.2.0.0/16"]
}

resource "google_compute_firewall" "allow_vpc2_to_vpc1" {
  name    = "allow-vpc2-to-vpc1"
  network = google_compute_network.vpc2.name

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/16"]
}

resource "google_compute_instance" "vm_vpc1" {
  name         = "spatil-vm-vpc1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc1.id
    subnetwork = google_compute_subnetwork.subnet1.id
  }
}

resource "google_compute_instance" "vm_vpc2" {
  name         = "spatil-vm-vpc2"
  machine_type = "e2-micro"
  zone         = "asia-south1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc2.id
    subnetwork = google_compute_subnetwork.subnet2.id
  }
}
