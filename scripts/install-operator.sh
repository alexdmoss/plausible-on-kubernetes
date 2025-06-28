#!/usr/bin/env bash
set -euoE pipefail

if [[ -z "${GCP_PROJECT_ID:-}" ]]; then
  echo "-> [ERROR] GCP_PROJECT_ID must be set"
  exit 1
fi

pushd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null

kubectl apply --server-side -f ./k8s/cnpg-1.26.0.yaml

popd >/dev/null
