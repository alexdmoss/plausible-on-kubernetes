#!/usr/bin/env bash
set -euoE pipefail

if [[ -z ${GCP_PROJECT_ID:-} ]]; then
  echo "Missing GCP Project"
  exit 1
fi

pushd "$(dirname "${BASH_SOURCE[0]}")/terraform" > /dev/null

echo "-> Initialising terraform"
terraform init -backend-config=bucket="${GCP_PROJECT_ID}"-apps-tfstate -backend-config=prefix=plausible

echo "-> Applying terraform"
terraform apply -auto-approve -var gcp_project_id="${GCP_PROJECT_ID}"

popd > /dev/null
