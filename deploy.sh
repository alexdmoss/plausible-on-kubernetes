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

  ADMIN_USER_EMAIL=$(gcloud secrets versions access latest --secret="PLAUSIBLE_ADMIN_USER_EMAIL" --project="${GCP_PROJECT_ID}")
  ADMIN_USER_NAME=$(gcloud secrets versions access latest --secret="PLAUSIBLE_ADMIN_USER_NAME" --project="${GCP_PROJECT_ID}")
  ADMIN_USER_PWD=$(gcloud secrets versions access latest --secret="PLAUSIBLE_ADMIN_USER_PWD" --project="${GCP_PROJECT_ID}")
  SECRET_KEY_BASE=$(gcloud secrets versions access latest --secret="PLAUSIBLE_SECRET_KEY_BASE" --project="${GCP_PROJECT_ID}")

  POSTGRES_USER=$(gcloud secrets versions access latest --secret="PLAUSIBLE_POSTGRES_USER" --project="${GCP_PROJECT_ID}")
  POSTGRES_PASSWORD=$(gcloud secrets versions access latest --secret="PLAUSIBLE_POSTGRES_PASSWORD" --project="${GCP_PROJECT_ID}")
  CLICKHOUSE_USER=$(gcloud secrets versions access latest --secret="PLAUSIBLE_CLICKHOUSE_USER" --project="${GCP_PROJECT_ID}")
  CLICKHOUSE_PASSWORD=$(gcloud secrets versions access latest --secret="PLAUSIBLE_CLICKHOUSE_PASSWORD" --project="${GCP_PROJECT_ID}")

  SENDGRID_KEY=$(gcloud secrets versions access latest --secret="PLAUSIBLE_SENDGRID_KEY" --project="${GCP_PROJECT_ID}")

  GOOGLE_CLIENT_ID=$(gcloud secrets versions access latest --secret="PLAUSIBLE_GOOGLE_CLIENT_ID" --project="${GCP_PROJECT_ID}")
  GOOGLE_CLIENT_SECRET=$(gcloud secrets versions access latest --secret="PLAUSIBLE_GOOGLE_CLIENT_SECRET" --project="${GCP_PROJECT_ID}")

  TWITTER_CONSUMER_KEY=$(gcloud secrets versions access latest --secret="PLAUSIBLE_TWITTER_CONSUMER_KEY" --project="${GCP_PROJECT_ID}")
  TWITTER_CONSUMER_SECRET=$(gcloud secrets versions access latest --secret="PLAUSIBLE_TWITTER_CONSUMER_SECRET" --project="${GCP_PROJECT_ID}")
  TWITTER_ACCESS_TOKEN=$(gcloud secrets versions access latest --secret="PLAUSIBLE_TWITTER_ACCESS_TOKEN" --project="${GCP_PROJECT_ID}")
  TWITTER_ACCESS_TOKEN_SECRET=$(gcloud secrets versions access latest --secret="PLAUSIBLE_TWITTER_ACCESS_TOKEN_SECRET" --project="${GCP_PROJECT_ID}")

  export ADMIN_USER_EMAIL ADMIN_USER_NAME ADMIN_USER_PWD SECRET_KEY_BASE SENDGRID_KEY GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET
  export POSTGRES_USER POSTGRES_PASSWORD CLICKHOUSE_USER CLICKHOUSE_PASSWORD
  export TWITTER_CONSUMER_KEY TWITTER_CONSUMER_SECRET TWITTER_ACCESS_TOKEN TWITTER_ACCESS_TOKEN_SECRET

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
