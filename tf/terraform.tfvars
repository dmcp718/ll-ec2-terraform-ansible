# AWS Provider Configuration
aws_region = "us-east-2"

# Instance Configuration
instance_type = "t3.xlarge"
instance_name = "ll-production-dpfs"
key_name = "us-east-2"
key_file = "/Users/davidphillips/Documents/Cloud_PEMs/us-east-2.pem"

# VPC Configuration
vpc_cidr = "10.0.0.0/24"
vpc_name = "ll-production-dpfs-vpc"

# Volume Configuration
root_volume_size = 30
data_volume_size = 100

# Mount Configuration
mount_point = "/media/production"

# Security Configuration
allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

# Resource Tags
project = "dpfs"
environment = "production"
owner = "dpadmin"

tags = {
  Application = "LucidLink"
  Service     = "production-dpfs"
  ManagedBy   = "terraform"
}
