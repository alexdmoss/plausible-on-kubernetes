#!/usr/bin/env bash
set -euoE pipefail

NAMESPACE=plausible

function main() {

  _assert_variables_set GCP_PROJECT_ID POSTGRES_VERSION CLICKHOUSE_VERSION PLAUSIBLE_VERSION

  if [[ -z ${1:-} ]]; then
    action="ALL"
  else
    action="${1}"
  fi

  if [[ $(kubectl get ns | grep -c "plausible") -eq 0 ]]; then
      _console_msg "Creating namespace ..." INFO true
      kubectl create ns ${NAMESPACE}
      kubectl label namespace ${NAMESPACE} istio-injection=enabled
  fi

  setup_secrets

  pushd "$(dirname "${BASH_SOURCE[0]}")/k8s/" > /dev/null

  if [[ "${action}" == "plausible-db" ]] || [[ ${action} == "ALL" ]]; then
    _console_msg "Deploying plausible-db ..." INFO true
    kustomize build ./plausible-db/ | envsubst "\$POSTGRES_VERSION \$POSTGRES_USER" | kubectl apply -f -
    kubectl rollout status sts/plausible-db -n=${NAMESPACE} --timeout=120s
  fi

  if [[ ${action} == "plausible-events-db" ]] || [[ ${action} == "ALL" ]]; then
    _console_msg "Deploying plausible-events-db ..." INFO true
    kustomize build ./plausible-events-db/ | envsubst "\$CLICKHOUSE_VERSION" | kubectl apply -f -
    kubectl rollout status sts/plausible-events-db -n=${NAMESPACE} --timeout=120s
  fi

  if [[ ${action} == "plausible-server" ]] || [[ ${action} == "ALL" ]]; then
    _console_msg "Deploying plausible-server ..." INFO true
    kustomize build ./plausible-server/ | envsubst "\$PLAUSIBLE_VERSION" | kubectl apply -f -
    kubectl rollout status deploy/plausible -n=${NAMESPACE} --timeout=180s
  fi

  popd >/dev/null

  _console_msg "Deployment complete" INFO true

}

function setup_secrets() {

  _console_msg "Creating secrets ..." INFO true

  pushd "$(dirname "${BASH_SOURCE[0]}")/" > /dev/null

  plausible_secrets=$(gcloud secrets versions access latest --secret="PLAUSIBLE" --project="${GCP_PROJECT_ID}")
  # shellcheck disable=2046
  export $(echo "${plausible_secrets}" | xargs)

  cat plausible-conf.env | \
    envsubst "\$ADMIN_USER_EMAIL \$ADMIN_USER_NAME \$ADMIN_USER_PWD \$BASE_URL \$SECRET_KEY_BASE" | \
    envsubst "\$POSTGRES_USER \$POSTGRES_PASSWORD \$CLICKHOUSE_USER \$CLICKHOUSE_PASSWORD" | \
    envsubst " \$SENDGRID_KEY \$GOOGLE_CLIENT_ID \$GOOGLE_CLIENT_SECRET" | \
    envsubst "\$TWITTER_CONSUMER_KEY \$TWITTER_CONSUMER_SECRET \$TWITTER_ACCESS_TOKEN \$TWITTER_ACCESS_TOKEN_SECRET" \
    > k8s/base/plausible-conf.env.secret
  trap "rm -f k8s/base/plausible-conf.env.secret" EXIT

  popd >/dev/null

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

function _console_msg() {
  local msg=${1}
  local level=${2:-}
  local ts=${3:-}
  if [[ -z ${level} ]]; then level=INFO; fi
  if [[ -n ${ts} ]]; then ts=" [$(date +"%Y-%m-%d %H:%M")]"; fi

  echo ""
  if [[ ${level} == "ERROR" ]] || [[ ${level} == "CRIT" ]] || [[ ${level} == "FATAL" ]]; then
    (echo 2>&1)
    (echo >&2 "-> [${level}]${ts} ${msg}")
  else 
    (echo "-> [${level}]${ts} ${msg}")
  fi
}

main "$@"
