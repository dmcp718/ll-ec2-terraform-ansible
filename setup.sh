#!/bin/bash

set -e
set -a

# Default values
MOUNT_POINT="/data"
AWS_REGION="us-east-2"
INSTANCE_TYPE="t3.xlarge"
KEY_NAME="us-east-2"
KEY_FILE="/Users/davidphillips/Documents/Cloud_PEMs/us-east-2.pem"
VPC_CIDR="10.0.0.0/24"

# Parse command line arguments first
while [[ $# -gt 0 ]]; do
    case $1 in
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load environment variables if env file provided
if [[ -n "$ENV_FILE" ]]; then
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "Error: Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    # Source the environment file
    source "$ENV_FILE"
    
    # Export required variables with defaults
    export FILESPACE="${LL_FILESPACE}"
    export USERNAME="${LL_USERNAME}"
    export MOUNT_POINT="${LL_MOUNT_POINT:-/data}"
    export SERVICE_NAME="${FILESPACE//./-}"  # Replace dots with dashes for service name
    
    # Export AWS variables
    export AWS_REGION="${AWS_REGION:-us-east-2}"
    export INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-t3.xlarge}"
    export KEY_NAME="${AWS_KEY_NAME}"
    export KEY_FILE="${AWS_KEY_FILE}"
    export VPC_CIDR="${AWS_VPC_CIDR:-10.0.0.0/24}"
    export SUBNET_ID="${AWS_SUBNET_ID}"
    export SECURITY_GROUP_ID="${AWS_SECURITY_GROUP_ID}"

    # Validate required variables
    if [[ -z "$FILESPACE" ]] || [[ -z "$USERNAME" ]] || [[ -z "$MOUNT_POINT" ]] || [[ -z "$SERVICE_NAME" ]]; then
        echo "Error: Required variables not set in $ENV_FILE"
        echo "Required: LL_FILESPACE, LL_USERNAME, LL_MOUNT_POINT"
        exit 1
    fi

    # Debug output
    echo "Environment variables loaded:"
    echo "FILESPACE=${FILESPACE}"
    echo "USERNAME=${USERNAME}"
    echo "MOUNT_POINT=${MOUNT_POINT}"
    echo "SERVICE_NAME=${SERVICE_NAME}"
    echo "AWS_REGION=${AWS_REGION}"
    echo "INSTANCE_TYPE=${INSTANCE_TYPE}"
    echo "KEY_NAME=${KEY_NAME}"
    echo "KEY_FILE=${KEY_FILE}"
    echo "VPC_CIDR=${VPC_CIDR}"
fi

# Create necessary directories first
echo "Creating directory structure..."
mkdir -p ansible/roles/lucidlink/{tasks,templates,handlers}
mkdir -p ansible/group_vars/all

# Validate required parameters before asking for password
if [[ -z "$FILESPACE" || -z "$USERNAME" || -z "$KEY_NAME" || -z "$KEY_FILE" ]]; then
    echo "Error: Missing required parameters"
    echo "Required: FILESPACE, USERNAME, KEY_NAME, KEY_FILE"
    exit 1
fi

# Function to read password securely
read_password() {
    local prompt="$1"
    local password

    while true; do
        echo -n "$prompt: " >&2
        read -s password
        echo >&2
        echo -n "Confirm $prompt: " >&2
        read -s password2
        echo >&2

        if [ "$password" = "$password2" ]; then
            echo "$password"
            return 0
        else
            echo "Passwords do not match. Please try again." >&2
        fi
    done
}

# Function to ensure vault password exists
ensure_vault_password() {
    if [[ ! -f ~/.ansible/vault_pass.txt ]]; then
        echo "Creating new Ansible vault password..."
        mkdir -p ~/.ansible
        VAULT_PASSWORD=$(read_password "Enter Ansible vault password")
        echo "$VAULT_PASSWORD" > ~/.ansible/vault_pass.txt
        chmod 600 ~/.ansible/vault_pass.txt
        unset VAULT_PASSWORD
    fi
}

# Function to create and encrypt vault file
create_vault_file() {
    # Get LucidLink password if not provided
    if [[ -z "$PASSWORD" ]]; then
        PASSWORD=$(read_password "Enter LucidLink password (used for authentication with LucidLink service)")
    fi

    # Create and encrypt vault file
    echo "Creating and encrypting vault file..."
    cat > ansible/group_vars/all/vault.yml << EOF
---
vault_lucidlink_password: "${PASSWORD}"
EOF

    ansible-vault encrypt ansible/group_vars/all/vault.yml --vault-password-file ~/.ansible/vault_pass.txt

    # Clear password from memory
    PASSWORD=""
}

# Handle vault setup
if [[ -f ansible/group_vars/all/vault.yml ]]; then
    read -p "Vault file already exists. Do you want to recreate it with a new password? (y/N) " recreate_vault
    if [[ "${recreate_vault}" == "y" ]] || [[ "${recreate_vault}" == "Y" ]]; then
        ensure_vault_password
        create_vault_file
    else
        echo "Using existing vault file."
    fi
else
    ensure_vault_password
    create_vault_file
fi

# Create Ansible task file
cat > ansible/roles/lucidlink/tasks/main.yml << EOF
---
- name: Wait for cloud-init to complete
  command: cloud-init status --wait
  changed_when: false

- name: Create password file
  copy:
    content: "PASSWORD='{{ vault_lucidlink_password }}'"
    dest: "/etc/{{ service_name }}.pwd"
    owner: root
    group: root
    mode: '0400'
  no_log: true

- name: Create LucidLink service file
  template:
    src: lucidlink.service.j2
    dest: "/etc/systemd/system/{{ service_name }}.service"
    owner: root
    group: root
    mode: '0644'
  notify: reload systemd

- name: Force systemd reload
  systemd:
    daemon_reload: yes

- name: Enable and start LucidLink service
  systemd:
    name: "{{ service_name }}"
    state: started
    enabled: yes
EOF

# Create Ansible handlers file
cat > ansible/roles/lucidlink/handlers/main.yml << EOF
---
- name: reload systemd
  systemd:
    daemon_reload: yes
EOF

# Create service template
cat > ansible/roles/lucidlink/templates/lucidlink.service.j2 << EOF
[Unit]
Description=LucidLink {{ filespace }} Daemon
After=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
EnvironmentFile=/etc/{{ service_name }}.pwd
Environment=HOME=/home/ubuntu
ExecStart=/usr/bin/bash -c "/usr/bin/lucid2 --instance 501 daemon"
ExecStartPost=/usr/bin/bash -c "until /usr/bin/lucid2 status | grep -q 'Unlinked' ; do continue ; done"
ExecStartPost=/usr/bin/bash -c "/usr/bin/lucid2 --instance 501 link --fs {{ filespace }} --user {{ username }} --mount-point {{ mount_point }} --root-path /data --fuse-allow-other --password '\${PASSWORD}'"
ExecStartPost=/usr/bin/bash -c "until /usr/bin/lucid2 --instance 501 status | grep -q 'Linked' ; do continue ; done"
ExecStartPost=/usr/bin/bash -c "/usr/bin/lucid2 --instance 501 config --set --DataCache.Size 95GB"
ExecStop=/usr/bin/bash -c "/usr/bin/lucid2 exit"
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Create cloud-init template
cat > ansible/roles/lucidlink/templates/cloud-init.yml.j2 << 'EOF'
#cloud-config
package_update: true
package_upgrade: true

packages:
  - curl
  - wget
  - git
  - vim
  - apt-transport-https
  - ca-certificates
  - software-properties-common
  - xfsprogs
  - fuse

write_files:
  - path: /etc/fuse.conf
    content: |
      user_allow_other
    append: true

runcmd:
  # System updates
  - DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
  
  # Install LucidLink
  - wget -q https://www.lucidlink.com/download/latest/lin64/stable/ -O /tmp/lucidinstaller.deb
  - apt-get install -y /tmp/lucidinstaller.deb
  
  # Install CloudWatch agent
  - wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
  - dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
  - rm /tmp/lucidinstaller.deb /tmp/amazon-cloudwatch-agent.deb

  # Identify and mount data volume
  - |
    ROOT_DEVICE=$(df / | tail -1 | awk '{print $1}')
    ROOT_BASE=$(basename $ROOT_DEVICE | sed 's/[0-9]*$//')
    echo "Root device: $ROOT_DEVICE (base: $ROOT_BASE)"

    # Find unformatted disk
    UNFORMATTED_DEVICE=$(lsblk -dn -o NAME,TYPE | grep disk | grep -v "$ROOT_BASE" | while read DEVICE TYPE; do
        if ! mount | grep -q "/dev/$DEVICE" && [ -z "$(lsblk -n /dev/$DEVICE | grep part)" ]; then
            echo "/dev/$DEVICE"
            break
        fi
    done)

    if [ -n "$UNFORMATTED_DEVICE" ]; then
        echo "Found unformatted device: $UNFORMATTED_DEVICE"
        mkfs.xfs -f $UNFORMATTED_DEVICE
        mkdir -p /data
        mount -t xfs $UNFORMATTED_DEVICE /data
        echo "$UNFORMATTED_DEVICE /data xfs defaults 0 2" >> /etc/fstab
        chown -R ubuntu:ubuntu /data
        chmod 755 /data
        echo "Data disk setup complete!"
    else
        echo "No unformatted device found"
        exit 1
    fi
EOF

# Create Ansible playbook
cat > ansible/site.yml << EOF
---
- hosts: lucidlink_hosts
  roles:
    - lucidlink
EOF

# Create Ansible inventory template
cat > ansible/inventory << EOF
[lucidlink_hosts]
# This will be populated by tf-apply.sh
EOF

# Create Terraform configuration
mkdir -p tf
cat > tf/main.tf << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${AWS_REGION}"
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

resource "aws_instance" "lucidlink" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "${INSTANCE_TYPE}"
  key_name      = "${KEY_NAME}"
  ${SUBNET_ID:+"subnet_id = \"${SUBNET_ID}\""}
  ${SECURITY_GROUP_ID:+"vpc_security_group_ids = [\"${SECURITY_GROUP_ID}\"]"}

  root_block_device {
    volume_size          = 40
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
    private_key = file("${KEY_FILE}")
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
EOF

# Create Terraform variables file
cat > tf/terraform.tfvars << EOF
aws_region       = "${AWS_REGION}"
instance_type    = "${INSTANCE_TYPE}"
key_name         = "${KEY_NAME}"
vpc_cidr         = "${VPC_CIDR}"

tags = {
  Name        = "lucidlink-instance"
  Environment = "production"
  Terraform   = "true"
}
EOF

# Create Terraform outputs
cat > tf/outputs.tf << EOF
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.lucidlink.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lucidlink.id
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.lucidlink.private_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${KEY_FILE} ubuntu@\${aws_instance.lucidlink.public_ip}"
}
EOF

echo "Setup complete! Generated Ansible playbook and templates."
echo "Service name will be: $SERVICE_NAME"
echo ""
echo "Next steps:"
echo "1. Run ./tf-apply.sh to deploy infrastructure and configure LucidLink"
echo "2. Use ./tf-destroy.sh when you want to tear down the infrastructure"
