#!/bin/bash
# ACME Multi-Cloud Infrastructure - Setup Script
# This script helps set up the environment for deploying the infrastructure

set -e

echo "================================================"
echo "ACME Multi-Cloud Infrastructure Setup"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required tools are installed
echo "Checking required tools..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

all_tools_present=true

check_command terraform || all_tools_present=false
check_command gcloud || all_tools_present=false
check_command aws || all_tools_present=false
check_command kubectl || all_tools_present=false

echo ""

if [ "$all_tools_present" = false ]; then
    echo -e "${RED}ERROR:${NC} Some required tools are missing. Please install them before continuing."
    echo ""
    echo "Installation instructions:"
    echo "  - Terraform: https://www.terraform.io/downloads"
    echo "  - gcloud CLI: https://cloud.google.com/sdk/docs/install"
    echo "  - AWS CLI: https://aws.amazon.com/cli/"
    echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if terraform.tfvars exists
echo ""
echo "Checking configuration..."

if [ ! -f terraform.tfvars ]; then
    echo -e "${YELLOW}WARNING:${NC} terraform.tfvars not found"
    echo "Creating from terraform.tfvars.example..."
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${GREEN}✓${NC} Created terraform.tfvars"
    echo ""
    echo -e "${YELLOW}IMPORTANT:${NC} Please edit terraform.tfvars and update the following:"
    echo "  - gcp_project: Your GCP project ID"
    echo "  - enable_gcp: Set to true/false to enable/disable GCP"
    echo "  - enable_aws: Set to true/false to enable/disable AWS"
    echo ""
    read -p "Press Enter after updating terraform.tfvars..."
else
    echo -e "${GREEN}✓${NC} terraform.tfvars exists"
fi

# Check GCP authentication
echo ""
echo "Checking cloud provider authentication..."

if gcloud auth application-default print-access-token &> /dev/null; then
    echo -e "${GREEN}✓${NC} GCP authentication configured"
    GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$GCP_PROJECT" ]; then
        echo "  Current GCP project: $GCP_PROJECT"
    fi
else
    echo -e "${YELLOW}WARNING:${NC} GCP authentication not configured"
    echo "Run: gcloud auth application-default login"
fi

# Check AWS authentication
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS authentication configured"
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    AWS_REGION=$(aws configure get region 2>/dev/null)
    if [ -n "$AWS_ACCOUNT" ]; then
        echo "  AWS Account ID: $AWS_ACCOUNT"
        echo "  AWS Region: ${AWS_REGION:-not set}"
    fi
else
    echo -e "${YELLOW}WARNING:${NC} AWS authentication not configured"
    echo "Run: aws configure"
fi

# Initialize Terraform
echo ""
echo "================================================"
echo "Initializing Terraform..."
echo "================================================"
echo ""

terraform init

echo ""
echo -e "${GREEN}✓${NC} Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Review terraform.tfvars and ensure all values are correct"
echo "  2. Run: terraform plan -out=tfplan"
echo "  3. Review the plan output"
echo "  4. Run: terraform apply tfplan"
echo ""
echo "For more information, see README.md"
