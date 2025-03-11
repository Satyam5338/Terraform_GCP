provider "google" {
  project = "sp-terra-project"
  region  = "us-central1"
}

# Create VPC Network
resource "google_compute_network" "my_vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

# Public Subnet 1
resource "google_compute_subnetwork" "public_subnet_1" {
  name          = "public-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.my_vpc.id
}

# Public Subnet 2
resource "google_compute_subnetwork" "public_subnet_2" {
  name          = "public-subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.my_vpc.id
}

# Private Subnet 1
resource "google_compute_subnetwork" "private_subnet_1" {
  name          = "private-subnet-1"
  ip_cidr_range = "10.0.3.0/24"
  region        = "us-central1"
  network       = google_compute_network.my_vpc.id
  private_ip_google_access = true
}

# Private Subnet 2
resource "google_compute_subnetwork" "private_subnet_2" {
  name          = "private-subnet-2"
  ip_cidr_range = "10.0.4.0/24"
  region        = "us-central1"
  network       = google_compute_network.my_vpc.id
  private_ip_google_access = true
}

# Internet Gateway (Default route for public subnet)
resource "google_compute_route" "default_internet_route" {
  name                   = "default-internet-route"
  network                = google_compute_network.my_vpc.id
  dest_range             = "0.0.0.0/0"
  next_hop_gateway       = "default-internet-gateway"
  priority               = 1000
}

# Cloud Router for NAT
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.my_vpc.id
  region  = "us-central1"
}

# Cloud NAT for Private Subnets
resource "google_compute_router_nat" "cloud_nat" {
  name                               = "cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = google_compute_router.nat_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall Rule to Allow SSH in Public Subnets
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.my_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
