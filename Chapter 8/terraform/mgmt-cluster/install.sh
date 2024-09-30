#!/bin/bash
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"

echo -e "${GREEN}Installing with the following options: ${NC}"
echo -e "${GREEN}----------------------------------------------------${NC}"
echo -e "${PURPLE}\nTargets:${NC}"
echo "AWS profile (if set): ${AWS_PROFILE}"
echo "AWS account number: $(aws sts get-caller-identity --query "Account" --output text)"

# The rest of the steps are defined as a Terraform module. Parse the config to JSON and use it as the Terraform variable file. This is done because JSON doesn't allow you to easily place comments.
cd "${REPO_ROOT}/${SUB_LEVEL}/terraform/mgmt-cluster"
terraform init -upgrade
terraform apply -auto-approve

aws eks --region us-west-2 update-kubeconfig --name modern-engineering

kubectl apply -f ./karpenter.yaml

export GITHUB_URL=$(yq '.repo_url' ${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml)

# Set up ArgoCD. We will use ArgoCD to install all components.
cd "${REPO_ROOT}/setups/argocd/"
./install.sh
cd -

# The rest of the steps are defined as a Terraform module. Parse the config to JSON and use it as the Terraform variable file. This is done because JSON doesn't allow you to easily place comments.
cd "${REPO_ROOT}/${SUB_LEVEL}/terraform/mgmt-cluster/day2-ops"
pwd
yq -o json '.'  "${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml" > terraform.tfvars.json

terraform init -upgrade
terraform apply -auto-approve
