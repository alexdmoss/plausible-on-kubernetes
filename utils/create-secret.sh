#!/usr/bin/env bash

# handy for generating the base key: openssl rand -base64 64 | tr -d '\n' ; echo

function create-secret() {
  local secret_id=${1:-}
  local secret_str=${2:-}
  if [[ -z ${secret_id} ]]; then 
    echo "Missing Secret ID"
    exit 1
  fi
  if [[ -z ${secret_str} ]]; then
    echo "Specify secret data to add to secret: ${secret_id}"
    read -r secret_str
  fi
  echo -n "${secret_str}" | gcloud secrets versions add "${secret_id}" --data-file=- --project="${GCP_PROJECT_ID}"
}

create-secret "$@"
