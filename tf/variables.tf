variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "lucidlink-instance"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "lucidlink"
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Default to all, should be overridden in production
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 100
}

variable "ami_owner_id" {
  description = "Owner ID of the AMI to use"
  type        = string
  default     = "099720109477" # Canonical/Ubuntu
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_name" {
  description = "Name tag for VPC"
  type        = string
  default     = "lucidlink-vpc"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "admin"
}

variable "mount_point" {
  description = "Mount point for LucidLink filespace"
  type        = string
  default     = "/media/lucidlink"
}

variable "key_file" {
  description = "Path to SSH private key file"
  type        = string
}
