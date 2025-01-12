variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "lucidlink-instance"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched. If empty, a new VPC and subnet will be created."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "ebs_volume_size" {
  description = "Size of the additional EBS volume in GB"
  type        = number
  default     = 100
}

variable "ebs_volume_type" {
  description = "Type of the EBS volume (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "IOPS for the EBS volume (if applicable)"
  type        = number
  default     = 3000
}

variable "ebs_throughput" {
  description = "Throughput for the EBS volume in MiB/s (if applicable)"
  type        = number
  default     = 500
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for the instance"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

variable "ami_owner_id" {
  description = "Owner ID of the AMI to use"
  type        = string
  default     = "099720109477" # Canonical/Ubuntu</find>
  type        = list(string)
  default     = []
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
