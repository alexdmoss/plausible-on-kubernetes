#!/bin/bash

if [[ -z ${GCP_PROJECT_ID} ]]; then echo "-> [ERROR] GCP_PROJECT_ID not set"; exit 1; fi

INSTANCE=postgres-instance-01

POSTGRES_USER=$(gcloud secrets versions access latest --secret="PLAUSIBLE_POSTGRES_USER" --project="${GCP_PROJECT_ID}")
POSTGRES_PASSWORD=$(gcloud secrets versions access latest --secret="PLAUSIBLE_POSTGRES_PASSWORD" --project="${GCP_PROJECT_ID}")
CLICKHOUSE_USER=$(gcloud secrets versions access latest --secret="PLAUSIBLE_CLICKHOUSE_USER" --project="${GCP_PROJECT_ID}")
CLICKHOUSE_PASSWORD=$(gcloud secrets versions access latest --secret="PLAUSIBLE_CLICKHOUSE_PASSWORD" --project="${GCP_PROJECT_ID}")

gcloud sql users create "${POSTGRES_USER}" --instance=${INSTANCE} --password="${POSTGRES_PASSWORD}" --project="${GCP_PROJECT_ID}"
gcloud sql users create "${CLICKHOUSE_USER}" --instance=${INSTANCE} --password="${CLICKHOUSE_PASSWORD}" --project="${GCP_PROJECT_ID}"