#!/bin/bash
# ACME Multi-Cloud Infrastructure - Validation Script
# This script validates the deployed infrastructure

set -e

echo "================================================"
echo "ACME Multi-Cloud Infrastructure Validation"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Terraform state exists
if [ ! -f terraform.tfstate ]; then
    echo -e "${RED}ERROR:${NC} No terraform.tfstate found. Have you deployed the infrastructure?"
    exit 1
fi

# Get deployment status from Terraform outputs
echo "Checking deployment status..."
echo ""

GCP_ENABLED=$(terraform output -raw deployment_summary 2>/dev/null | grep -o '"gcp_enabled":[^,}]*' | cut -d':' -f2 | tr -d ' ')
AWS_ENABLED=$(terraform output -raw deployment_summary 2>/dev/null | grep -o '"aws_enabled":[^,}]*' | cut -d':' -f2 | tr -d ' ')

echo "Deployment Configuration:"
echo "  GCP Enabled: $GCP_ENABLED"
echo "  AWS Enabled: $AWS_ENABLED"
echo ""

# Validate GCP resources
if [ "$GCP_ENABLED" = "true" ]; then
    echo -e "${BLUE}Validating GCP Resources...${NC}"
    echo ""
    
    GCP_CLUSTER=$(terraform output -raw gcp_cluster_name 2>/dev/null)
    GCP_REGION=$(terraform output -json deployment_summary 2>/dev/null | grep -o '"gcp_region":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    
    if [ -n "$GCP_CLUSTER" ]; then
        echo "GKE Cluster: $GCP_CLUSTER"
        
        # Check cluster status
        if gcloud container clusters describe "$GCP_CLUSTER" --region "$GCP_REGION" &> /dev/null; then
            STATUS=$(gcloud container clusters describe "$GCP_CLUSTER" --region "$GCP_REGION" --format="value(status)" 2>/dev/null)
            if [ "$STATUS" = "RUNNING" ]; then
                echo -e "${GREEN}✓${NC} GKE cluster is running"
                
                # Get kubectl credentials
                gcloud container clusters get-credentials "$GCP_CLUSTER" --region "$GCP_REGION" &> /dev/null
                
                # Check nodes
                NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
                echo -e "${GREEN}✓${NC} GKE has $NODE_COUNT node(s) ready"
            else
                echo -e "${YELLOW}⚠${NC} GKE cluster status: $STATUS"
            fi
        else
            echo -e "${RED}✗${NC} Could not access GKE cluster"
        fi
    fi
    
    echo ""
fi

# Validate AWS resources
if [ "$AWS_ENABLED" = "true" ]; then
    echo -e "${BLUE}Validating AWS Resources...${NC}"
    echo ""
    
    AWS_CLUSTER=$(terraform output -raw aws_cluster_name 2>/dev/null)
    AWS_REGION=$(terraform output -json deployment_summary 2>/dev/null | grep -o '"aws_region":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    
    if [ -n "$AWS_CLUSTER" ]; then
        echo "EKS Cluster: $AWS_CLUSTER"
        
        # Check cluster status
        if aws eks describe-cluster --name "$AWS_CLUSTER" --region "$AWS_REGION" &> /dev/null; then
            STATUS=$(aws eks describe-cluster --name "$AWS_CLUSTER" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null)
            if [ "$STATUS" = "ACTIVE" ]; then
                echo -e "${GREEN}✓${NC} EKS cluster is active"
                
                # Get kubectl credentials
                aws eks update-kubeconfig --name "$AWS_CLUSTER" --region "$AWS_REGION" &> /dev/null
                
                # Check nodes
                NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
                echo -e "${GREEN}✓${NC} EKS has $NODE_COUNT node(s) ready"
            else
                echo -e "${YELLOW}⚠${NC} EKS cluster status: $STATUS"
            fi
        else
            echo -e "${RED}✗${NC} Could not access EKS cluster"
        fi
    fi
    
    echo ""
fi

echo "================================================"
echo "Validation Complete"
echo "================================================"
echo ""
echo "For detailed information, run:"
echo "  terraform output"
echo ""
echo "To access clusters:"
if [ "$GCP_ENABLED" = "true" ]; then
    echo "  GCP: terraform output gcp_kubectl_command"
fi
if [ "$AWS_ENABLED" = "true" ]; then
    echo "  AWS: terraform output aws_kubectl_command"
fi
echo ""
