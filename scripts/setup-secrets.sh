#!/usr/bin/env bash
set -euoE pipefail

if [[ -z "${GCP_PROJECT_ID:-}" ]]; then
  echo "-> [ERROR] GCP_PROJECT_ID must be set"
  exit 1
fi

pushd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null

plausible_secrets=$(gcloud secrets versions access latest --secret="PLAUSIBLE" --project="${GCP_PROJECT_ID}")
# shellcheck disable=2046
export $(echo "${plausible_secrets}" | xargs)

cat plausible-conf.env | \
  envsubst "\$ADMIN_USER_EMAIL \$ADMIN_USER_NAME \$ADMIN_USER_PWD" | \
  envsubst "\$BASE_URL \$SECRET_KEY_BASE \$TOTP_VAULT_KEY" | \
  envsubst "\$POSTGRES_USER \$POSTGRES_PASSWORD \$CLICKHOUSE_USER \$CLICKHOUSE_PASSWORD" | \
  envsubst " \$SENDGRID_KEY \$GOOGLE_CLIENT_ID \$GOOGLE_CLIENT_SECRET" | \
  envsubst "\$TWITTER_CONSUMER_KEY \$TWITTER_CONSUMER_SECRET \$TWITTER_ACCESS_TOKEN \$TWITTER_ACCESS_TOKEN_SECRET" \
  > k8s/secret/plausible-conf.env.secret

kustomize build k8s/secret/ | kubectl apply -f -

kubectl delete secret plausible-db-pass --ignore-not-found=true
kubectl create secret generic plausible-db-pass --from-literal="password=${POSTGRES_PASSWORD}" --from-literal="username=${POSTGRES_USER}"

trap "rm -f k8s/secret/plausible-conf.env.secret" EXIT

popd >/dev/null
