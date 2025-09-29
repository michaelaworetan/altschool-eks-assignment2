# Fetches all available availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Creates the main VPC for Innovatemart
resource "aws_vpc" "innovatemart_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "innovatemart-vpc"
  }
}

# Create public subnets across availability zones
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.innovatemart_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = {
    Name = "innovatemart-public-subnet-${count.index + 1}"
  }
}

# Create private subnets across availability zones
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.innovatemart_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "innovatemart-private-subnet-${count.index + 1}"
  }
}

# Create an Internet Gateway for external connectivity
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.innovatemart_vpc.id

  tags = {
    Name = "innovatemart-igw"
  }
}

# Create a public route table with a default route to the Internet Gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.innovatemart_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "innovatemart-public-route-table"
  }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}
