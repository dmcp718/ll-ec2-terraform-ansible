#!/bin/bash

set -e

# Function to cleanup terraform state lock
cleanup_tf_lock() {
    if [ -f "tf/.terraform.tfstate.lock.info" ]; then
        rm -f "tf/.terraform.tfstate.lock.info"
        echo "Cleaned up Terraform state lock"
    fi
}

# Set trap to cleanup on script exit
trap cleanup_tf_lock EXIT

# Check if terraform directory exists
if [ ! -d "tf" ]; then
    echo "Error: 'tf' directory not found"
    exit 1
fi

# Show current infrastructure details
echo "Current infrastructure details:"
echo "-----------------------------"
(cd tf && {
    echo "Instance ID: $(terraform output -raw instance_id 2>/dev/null || echo 'N/A')"
    echo "Public IP: $(terraform output -raw public_ip 2>/dev/null || echo 'N/A')"
    echo "SSH Command: $(terraform output -raw ssh_command 2>/dev/null || echo 'N/A')"
    echo "-----------------------------"
})

# Prompt for confirmation
read -p "Are you sure you want to destroy this infrastructure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Destruction cancelled"
    exit 1
fi

echo "Destroying infrastructure..."
(cd tf && terraform destroy -auto-approve) || {
    echo "Terraform destroy failed. Cleaning up state lock..."
    cleanup_tf_lock
    exit 1
}

echo "Infrastructure destroyed successfully"
