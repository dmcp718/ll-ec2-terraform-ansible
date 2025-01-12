terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "this" {
  byte_length = 4
}

resource "aws_instance" "lucidlink" {
  ami           = data.aws_ami.ubuntu.id
  vpc_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.instance.id]
  instance_type = var.instance_type
  subnet_id     = var.subnet_id != "" ? var.subnet_id : module.vpc.public_subnets[0]
  tags = {
    Name = var.instance_name
  }
  key_name      = "us-east-2"
  
  

  root_block_device {
    volume_size          = var.root_volume_size
    volume_type          = var.ebs_volume_type
    iops                 = var.ebs_iops
    throughput           = var.ebs_throughput
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    iops       = var.ebs_iops
    throughput = var.ebs_throughput
  }

  user_data = templatefile("../ansible/roles/lucidlink/templates/cloud-init.yml.j2", {
    mount_point = "/data"
  })

  user_data_replace_on_change = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "sudo cloud-init status --wait",
      "echo 'Cloud-init complete'",
      "sudo cloud-init status --long"
    ]
  }

  tags = {
    Name = "LucidLink-Instance"
  }
}
