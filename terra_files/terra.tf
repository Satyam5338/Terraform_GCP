provider "aws" {
  region = "ap-south-2"
}

resource "aws_vpc" "sp-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sp-vpc"
  }
}

resource "aws_subnet" "sp-public" {
  vpc_id                  = aws_vpc.sp-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-2a"

  tags = {
    Name = "sp-public-subnet"
  }
}

resource "aws_subnet" "sp-private" {
  vpc_id            = aws_vpc.sp-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-2a"

  tags = {
    Name = "sp-private-subnet"
  }
}

resource "aws_subnet" "sp-db" {
  vpc_id            = aws_vpc.sp-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-2a"

  tags = {
    Name = "sp-db-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sp-vpc.id

  tags = {
    Name = "sp-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "sp-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.sp-public.id
  route_table_id = aws_route_table.public.id
}


