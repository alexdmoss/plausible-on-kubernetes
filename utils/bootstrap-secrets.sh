#!/usr/bin/env bash

if [[ -z ${GCP_PROJECT_ID} ]]; then echo "-> [ERROR] GCP_PROJECT_ID not set"; exit 1; fi

gcloud services enable secretmanager.googleapis.com --project="${GCP_PROJECT_ID}"

### moved all to one secret
gcloud secrets create PLAUSIBLE --project="${GCP_PROJECT_ID}"
