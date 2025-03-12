provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "sm_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "sm-vpc" }
}

resource "aws_subnet" "sm_public_subnet" {
  vpc_id                  = aws_vpc.sm_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "sm-public-subnet" }
}

resource "aws_internet_gateway" "sm_igw" {
  vpc_id = aws_vpc.sm_vpc.id
  tags = { Name = "sm-igw" }
}

resource "aws_route_table" "sm_route_table" {
  vpc_id = aws_vpc.sm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sm_igw.id
  }
  tags = { Name = "sm-route-table" }
}

resource "aws_route_table_association" "sm_public_assoc" {
  subnet_id      = aws_subnet.sm_public_subnet.id
  route_table_id = aws_route_table.sm_route_table.id
}

resource "aws_security_group" "sm_batch_sg" {
  vpc_id = aws_vpc.sm_vpc.id
  name   = "sm-batch-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "sm_batch_service_role" {
  name = "sm-batch-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "batch.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sm_batch_service_policy" {
  role       = aws_iam_role.sm_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_s3_bucket" "sm_input_bucket" {
  bucket = "sm-input-bucket"
}

resource "aws_s3_bucket" "sm_output_bucket" {
  bucket = "sm-output-bucket01"
}

data "aws_iam_instance_profile" "sm_batch_instance_profile" {
  name = "sm-batch-instance-profile"
}

resource "aws_batch_compute_environment" "sm_compute_env" {
  compute_environment_name = "sm-compute-env"
  type                     = "MANAGED"

  compute_resources {
    type              = "EC2"
    min_vcpus        = 0
    max_vcpus        = 2
    desired_vcpus    = 1
    instance_type   = ["m5.large"]
    subnets         = [aws_subnet.sm_public_subnet.id]
    security_group_ids = [aws_security_group.sm_batch_sg.id]
    instance_role    = data.aws_iam_instance_profile.sm_batch_instance_profile.arn
  }
  service_role = aws_iam_role.sm_batch_service_role.arn
}

resource "aws_batch_job_queue" "sm_job_queue" {
  name     = "sm-job-queue"
  state    = "Enabled"
  priority = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.sm_compute_env.arn
  }
}

resource "aws_cloudwatch_log_group" "sm_batch_log_group" {
  name = "/aws/batch/sm-job-logs"
}
resource "aws_batch_job_definition" "sm_job_definition" {
  name = "sm-job-definition"
  type = "container"
  container_properties = <<EOF
{
  "image": "amazonlinux",
  "command": ["echo", "Hello Satyam"],
  "memory": 512,
  "vcpus": 1,
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${aws_cloudwatch_log_group.sm_batch_log_group.name}",
      "awslogs-region": "us-east-1",
      "awslogs-stream-prefix": "sm"
    }
  }
}
EOF
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.sm_vpc.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet."
  value       = aws_subnet.sm_public_subnet.id
}

output "internet_gateway_id" {
  description = "The ID of the internet gateway."
  value       = aws_internet_gateway.sm_igw.id
}

output "route_table_id" {
  description = "The ID of the route table."
  value       = aws_route_table.sm_route_table.id
}

output "security_group_id" {
  description = "The ID of the security group."
  value       = aws_security_group.sm_batch_sg.id
}

output "batch_compute_environment_arn" {
  description = "The ARN of the AWS Batch compute environment."
  value       = aws_batch_compute_environment.sm_compute_env.arn
}

output "batch_job_queue_arn" {
  description = "The ARN of the AWS Batch job queue."
  value       = aws_batch_job_queue.sm_job_queue.arn
}

output "batch_job_definition_arn" {
  description = "The ARN of the AWS Batch job definition."
  value       = aws_batch_job_definition.sm_job_definition.arn
}

output "s3_input_bucket_name" {
  description = "The name of the S3 input bucket."
  value       = aws_s3_bucket.sm_input_bucket.bucket
}

output "s3_output_bucket_name" {
  description = "The name of the S3 output bucket."
  value       = aws_s3_bucket.sm_output_bucket.bucket
}

output "batch_service_role_arn" {
  description = "The ARN of the Batch service role."
  value       = aws_iam_role.sm_batch_service_role.arn
}
