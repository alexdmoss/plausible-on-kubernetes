#!/usr/bin/env bash

if [[ -z ${GCP_PROJECT_ID} ]]; then echo "-> [ERROR] GCP_PROJECT_ID not set"; exit 1; fi

gcloud secrets create PLAUSIBLE_ADMIN_USER_EMAIL --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_ADMIN_USER_NAME --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_ADMIN_USER_PWD --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_BASE_URL --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_SECRET_KEY_BASE --project="${GCP_PROJECT_ID}"

gcloud secrets create PLAUSIBLE_POSTGRES_USER --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_POSTGRES_PASSWORD --project="${GCP_PROJECT_ID}"

gcloud secrets create PLAUSIBLE_CLICKHOUSE_USER --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_CLICKHOUSE_PASSWORD --project="${GCP_PROJECT_ID}"

gcloud secrets create PLAUSIBLE_GOOGLE_CLIENT_ID --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_GOOGLE_CLIENT_SECRET --project="${GCP_PROJECT_ID}"

gcloud secrets create PLAUSIBLE_TWITTER_CONSUMER_KEY --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_TWITTER_CONSUMER_SECRET --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_TWITTER_ACCESS_TOKEN --project="${GCP_PROJECT_ID}"
gcloud secrets create PLAUSIBLE_TWITTER_ACCESS_TOKEN_SECRET --project="${GCP_PROJECT_ID}"

gcloud secrets create PLAUSIBLE_SENDGRID_KEY --project="${GCP_PROJECT_ID}"
