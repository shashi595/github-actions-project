# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Modify as needed
}

# Data source for availability zones
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ecs-nginx-vpc"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count = 2
  cidr_block = cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    Name = "ecs-nginx-public-subnet-${count.index}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a Security Group for the Nginx application (allows HTTP traffic)
resource "aws_security_group" "nginx_sg" {
  name_prefix = "nginx-sg-"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be more restrictive in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "nginx-cluster"
}
