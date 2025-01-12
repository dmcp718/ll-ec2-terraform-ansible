# LucidLink EC2 Terraform & Ansible Deployment

This repository contains Infrastructure as Code (IaC) for deploying LucidLink on AWS EC2 instances using Terraform and Ansible. The deployment includes a complete VPC setup with public and private subnets, security groups, and necessary VPC endpoints for AWS services.

## Infrastructure Overview

The deployment creates the following resources:

- **VPC Infrastructure**:
  - VPC with configurable CIDR block
  - 3 public and 3 private subnets across availability zones
  - NAT Gateways for private subnet internet access
  - VPC Endpoints for AWS services (S3, SSM, SSMMessages, EC2Messages)

- **EC2 Instance**:
  - Ubuntu-based EC2 instance
  - EBS volumes for root and data
  - Security group with required access rules
  - Automatic mounting of data volume

- **LucidLink Service**:
  - Systemd service configuration
  - Automatic startup and mounting
  - Secure password management using Ansible Vault

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
   - Adjust VPC CIDR if needed
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
# LucidLink Configuration
LL_FILESPACE="filespace.domain"    # Your LucidLink filespace name
LL_USERNAME="username"             # Your LucidLink username
LL_MOUNT_POINT="/data"             # Mount point for the filespace

# AWS Configuration
AWS_REGION="us-east-2"             # AWS region
AWS_INSTANCE_TYPE="t3.xlarge"      # EC2 instance type
AWS_VPC_CIDR="10.0.0.0/24"        # VPC CIDR block
AWS_KEY_NAME="your-key-pair"       # AWS key pair name
AWS_KEY_FILE="~/.ssh/key.pem"      # Path to SSH private key
```

### Terraform Variables

Key Terraform variables that can be customized:

- `instance_type`: EC2 instance type (default: t3.xlarge)
- `root_volume_size`: Size of root volume in GB (default: 30)
- `data_volume_size`: Size of data volume in GB (default: 100)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/24)

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

## Security

- Passwords are stored securely using Ansible Vault
- Security groups are configured with minimal required access
- VPC endpoints are used for AWS service access
- Private subnets are used for enhanced security

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