#!/bin/bash

set -e

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

# Check if env file provided
if [[ -z "$ENV_FILE" ]]; then
    echo "Error: --env-file argument is required"
    echo "Usage: $0 --env-file <env_file>"
    exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Export required variables with defaults
export FILESPACE="${LL_FILESPACE}"
export USERNAME="${LL_USERNAME}"
export MOUNT_POINT="${LL_MOUNT_POINT:-/media/lucidlink}"
export SERVICE_NAME="${FILESPACE//./-}"  # Replace dots with dashes for service name
export AWS_REGION="${AWS_REGION:-us-east-2}"
export INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-t3.xlarge}"
export KEY_NAME="${AWS_KEY_NAME}"
export KEY_FILE="${AWS_KEY_FILE}"
export VPC_CIDR="${AWS_VPC_CIDR:-10.0.0.0/24}"
export PROJECT="${AWS_TAGS_PROJECT:-lucidlink}"
export ENVIRONMENT="${AWS_TAGS_ENVIRONMENT:-dev}"
export OWNER="${AWS_TAGS_OWNER:-admin}"

# Set Terraform log level to ERROR to reduce verbosity
export TF_LOG=ERROR

# Function to cleanup terraform state lock
cleanup_tf_lock() {
    if [ -f "tf/.terraform.tfstate.lock.info" ]; then
        rm -f "tf/.terraform.tfstate.lock.info"
        echo "Cleaned up Terraform state lock"
    fi
}

# Function to validate CIDR format
validate_cidr() {
    local cidr=$1
    # Check if CIDR matches format: x.x.x.x/x where x are numbers
    if [[ ! $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 1
    fi
    
    # Validate each octet
    IFS='/' read -r ip prefix <<< "$cidr"
    IFS='.' read -r -a octets <<< "$ip"
    
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            return 1
        fi
    done
    
    # Validate prefix length
    if [ "$prefix" -lt 16 ] || [ "$prefix" -gt 28 ]; then
        return 1
    fi
    
    return 0
}

# Set trap to cleanup on script exit
trap cleanup_tf_lock EXIT

# Check required variables
if [ -z "$FILESPACE" ] || [ -z "$USERNAME" ] || [ -z "$MOUNT_POINT" ] || [ -z "$SERVICE_NAME" ]; then
    echo "Error: Required variables not set in $ENV_FILE"
    echo "Missing one or more: LL_FILESPACE, LL_USERNAME, LL_MOUNT_POINT"
    exit 1
fi

# Validate VPC CIDR
if ! validate_cidr "$VPC_CIDR"; then
    echo "Error: Invalid VPC CIDR format or range: $VPC_CIDR"
    echo "CIDR must be in format x.x.x.x/x and within reasonable range (e.g., /16 to /28)"
    exit 1
fi

# Check if terraform directory exists
if [ ! -d "tf" ]; then
    echo "Error: 'tf' directory not found. Please run setup.sh first."
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
(cd tf && terraform init -no-color)

# Generate a Terraform plan and save it to a file
echo "Generating Terraform plan..."
(cd tf && terraform plan -out=tfplan -no-color)

# Apply the saved Terraform plan
echo "Applying Terraform configuration..."
(cd tf && terraform apply -auto-approve tfplan -no-color) || {
    echo "Terraform apply failed. Cleaning up state lock..."
    cleanup_tf_lock
    exit 1
}

# Get instance information
echo "Retrieving instance information..."
INSTANCE_ID=$(cd tf && terraform output -raw instance_id)
INSTANCE_IP=$(cd tf && terraform output -raw public_ip)

# Get VPC information
echo "Retrieving VPC information..."
VPC_ID=$(cd tf && terraform output -raw vpc_id)

PRIVATE_SUBNETS=$(cd tf && terraform output -json private_subnets | jq -r '. | join(", ")')
PUBLIC_SUBNETS=$(cd tf && terraform output -json public_subnets | jq -r '. | join(", ")')

if [ -n "$VPC_ID" ]; then
    echo "VPC ID: $VPC_ID"
    echo "Private Subnets: $PRIVATE_SUBNETS"
    echo "Public Subnets: $PUBLIC_SUBNETS"
fi

# Get security group information
echo "Retrieving security group information..."
INSTANCE_SG=$(cd tf && terraform output -raw instance_security_group_id)

echo "Instance ID: $INSTANCE_ID"
echo "Instance IP: $INSTANCE_IP"
echo "Instance Security Group: $INSTANCE_SG"
echo ""
echo "SSH command: ssh -i $KEY_FILE ubuntu@$INSTANCE_IP"
echo ""


# Update Ansible inventory
echo "[lucidlink_hosts]" > ansible/inventory
echo "$INSTANCE_IP ansible_host=$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_FILE" >> ansible/inventory

# Create Ansible inventory file
cat > ansible/inventory << EOF
[lucidlink_hosts]
${INSTANCE_IP} ansible_host=${INSTANCE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${KEY_FILE}
EOF

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i ansible/inventory ansible/site.yml --ask-vault-pass \
    -e "filespace=${FILESPACE} username=${USERNAME} mount_point=${MOUNT_POINT} service_name=${SERVICE_NAME}" \
    -e "ansible_become=true"

echo "Deployment complete!"
