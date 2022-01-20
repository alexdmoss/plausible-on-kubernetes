#!/usr/bin/env bash
set -euoE pipefail

NAMESPACE=plausible

function main() {

  _assert_variables_set BACKUP_BUCKET GCP_PROJECT_ID CLUSTER_NAME

  export BACKUP_BUCKET

  pushd terraform/ >/dev/null

  terraform init -backend-config=bucket="${GCP_PROJECT_ID}"-apps-tfstate -backend-config=prefix=velero
  
  terraform apply -auto-approve \
    -var bucket_name="${BACKUP_BUCKET}" \
    -var project_id="${GCP_PROJECT_ID}" \
    -var cluster_name="${CLUSTER_NAME}" \
    -var namespace="${NAMESPACE}"

  popd >/dev/null

  kubectl apply -f ./k8s/crd.yaml

  kustomize build ./k8s/ | envsubst '$BACKUP_BUCKET' | kubectl apply -f -

  kubectl rollout status deployment velero -n=${NAMESPACE}

}


function _assert_variables_set() {
  local error=0
  local varname
  for varname in "$@"; do
    if [[ -z "${!varname-}" ]]; then
      echo "${varname} must be set" >&2
      error=1
    fi
  done
  if [[ ${error} = 1 ]]; then
    exit 1
  fi
}

main "$@"
