data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [cidrsubnet(var.vpc_cidr, 2, 0)]  # /26 subnet
  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 12)] # /28 subnet
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "LucidLink-VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 1)  # Corrected subnet CIDR calculation
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "LucidLink-Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "LucidLink-IGW"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "LucidLink-RT"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this to your IP range for better security
  }

  tags = {
    Name = "LucidLink-SG"
  }
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  route_table_ids = [aws_route_table.main.id]
  tags = {
    Name = "LucidLink-S3-Endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.main.id]
  subnet_ids         = [aws_subnet.main.id]
  private_dns_enabled = true
  
  tags = {
    Name = "LucidLink-SSM-Endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.main.id]
  subnet_ids         = [aws_subnet.main.id]
  private_dns_enabled = true
  
  tags = {
    Name = "LucidLink-SSMMessages-Endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.main.id]
  subnet_ids         = [aws_subnet.main.id]
  private_dns_enabled = true
  
  tags = {
    Name = "LucidLink-EC2Messages-Endpoint"
  }
}
