terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
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
  byte_length = 8
}

resource "aws_instance" "lucidlink" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.xlarge"
  key_name      = "us-east-2"
  
  

  root_block_device {
    volume_size          = 30
    volume_type          = "gp3"
    iops                 = 3000
    throughput           = 500
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 100
    volume_type = "gp3"
    iops       = 3000
    throughput = 500
  }

  user_data = templatefile("../ansible/roles/lucidlink/templates/cloud-init.yml.j2", {
    mount_point = "/data"
  })

  user_data_replace_on_change = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/Users/davidphillips/Documents/Cloud_PEMs/us-east-2.pem")
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
