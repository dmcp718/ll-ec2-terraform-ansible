# LucidLink EC2 Terraform & Ansible Deployment

This repository contains Infrastructure as Code (IaC) for deploying LucidLink on AWS EC2 instances using Terraform and Ansible. The deployment uses the default VPC and includes security groups, instance configuration, and secure password management.

## Infrastructure Overview

The deployment creates the following resources:

- **EC2 Instance**:
  - Ubuntu-based EC2 instance (configurable version, default: 22.04)
  - EBS volumes for root and data
  - Security group with required access rules
  - Automatic mounting of data volume

- **Security**:
  - Security group with:
    - SSH access (port 22)
    - Internal VPC communication
  - Secure password management using Ansible Vault

- **LucidLink Service**:
  - LucidLink v2 installation
  - Configurable data cache size
  - Systemd service configuration
  - Automatic startup and mounting
  - Secure password file in `/root/.lucidlink.pwd`

## Prerequisites

1. AWS CLI installed and configured
2. Terraform >= 1.0.0
3. Ansible >= 2.9
4. LucidLink account and credentials
5. AWS SSH key pair

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/dmcp718/ll-ec2-terraform-ansible.git
   cd ll-ec2-terraform-ansible
   ```

2. Create your environment file:
   ```bash
   cp env.template my-env
   ```

3. Edit `my-env` with your configuration:
   - Set your LucidLink credentials
   - Configure AWS settings
   - Set your SSH key details

4. Run the setup script:
   ```bash
   ./setup.sh --env-file my-env
   ```

5. Deploy the infrastructure:
   ```bash
   ./tf-apply.sh --env-file my-env
   ```

## Configuration Options

### Environment Variables

Key environment variables in `env.template`:

```bash
# LucidLink Configuration (Required)
LL_VERSION="2"                     # LucidLink version (default: 2)
LL_FILESPACE="filespace.domain"    # Your LucidLink filespace name
LL_USERNAME="username"             # Your LucidLink username
LL_MOUNT_POINT="/media/lucidlink"  # Where to mount the filespace (optional, default: /media/lucidlink)
LL_DATA_CACHE_SIZE="100GB"         # Data cache size (optional, default: 100GB)

# Ubuntu Configuration (Optional)
TF_VAR_ubuntu_version="22.04"      # Ubuntu version to use (optional, default: 22.04)

# AWS Configuration
AWS_REGION="us-east-1"             # AWS region for deployment (optional, default: us-east-1)
AWS_INSTANCE_TYPE="t3.xlarge"      # EC2 instance type (optional, default: t3.xlarge)

# Required AWS Configuration
AWS_KEY_NAME="your-key-pair"       # AWS key pair name (required)
AWS_KEY_FILE="~/.ssh/key.pem"      # Path to your SSH private key (required)

# AWS Tags (Optional)
AWS_TAGS_ENVIRONMENT="dev"         # Environment tag (optional, default: dev)
AWS_TAGS_OWNER="admin"            # Owner tag (optional, default: admin)
AWS_TAGS_PROJECT="lucidlink"      # Project tag (optional, default: lucidlink)

# AWS Volume Configuration (Optional)
AWS_ROOT_VOLUME_SIZE="30"         # Size of root volume in GB (optional, default: 30)
AWS_DATA_VOLUME_SIZE="100"        # Size of data volume in GB (optional, default: 100)

# Security Configuration (Optional)
AWS_ALLOWED_SSH_CIDRS="0.0.0.0/0" # Comma-separated list of CIDRs allowed to SSH (optional, default: 0.0.0.0/0)
```

### Security

The deployment includes several security features:

1. **Password Management**:
   - LucidLink password is stored securely using Ansible Vault
   - Password file is created with restricted permissions (0400)
   - Password file is stored in `/root/.lucidlink.pwd`

2. **Access Control**:
   - SSH access can be restricted to specific CIDR ranges
   - Security group rules limit access to required ports only
   - All sensitive files are owned by root with appropriate permissions

## Ansible Overview

The Ansible playbooks in this repository automate the configuration and deployment of the LucidLink service on EC2 instances. The playbooks handle tasks such as setting up systemd services, managing secure passwords, and ensuring idempotency across deployments.

## Running Ansible Playbooks

1. Ensure all prerequisites are met, including Ansible installation and AWS CLI configuration.

2. Navigate to the `ansible` directory:
   ```bash
   cd ansible
   ```

3. Execute the playbook using the following command:
   ```bash
   ansible-playbook site.yml -i inventory
   ```

4. Verify the deployment by checking the status of the LucidLink service on the EC2 instance.

## Environment-Specific Configurations

- Adjust the `group_vars` and `host_vars` to reflect the specific environment settings.
- Securely store sensitive variables using Ansible Vault.

## Directory Structure

```
.
├── ansible/                    # Ansible playbooks and roles
│   ├── roles/
│   │   └── lucidlink/         # LucidLink service configuration
│   └── site.yml               # Main Ansible playbook
├── tf/                        # Terraform configurations
│   ├── main.tf                # Main Terraform configuration
│   ├── vpc.tf                 # VPC configuration
│   ├── variables.tf           # Variable definitions
│   └── outputs.tf             # Output definitions
├── setup.sh                   # Initial setup script
├── tf-apply.sh               # Terraform apply wrapper script
└── env.template              # Environment template file
```

## Maintenance

### Updating LucidLink

The LucidLink service is configured to automatically update. However, if you need to manually update:

1. SSH into the instance
2. Stop the LucidLink service
3. Update the LucidLink client
4. Start the service

### Backup

The data volume can be backed up using AWS EBS snapshots. Consider setting up automated snapshots using AWS Backup.

## Troubleshooting

Common issues and solutions:

1. **SSH Connection Issues**:
   - Verify security group rules
   - Check key pair permissions
   - Ensure instance is in a public subnet

2. **LucidLink Mount Issues**:
   - Check service status: `systemctl status lucidlink`
   - Verify credentials in vault file
   - Check mount point permissions

3. **VPC Endpoint Issues**:
   - Verify endpoint security group rules
   - Check route table associations
   - Validate VPC CIDR ranges

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
