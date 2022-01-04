resource "google_project_service" "cloudsql-admin" {
  project = var.gcp_project_id
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
}

resource "google_sql_database_instance" "instance" {
  name             = "postgres-instance-01"
  project          = var.gcp_project_id
  database_version = "POSTGRES_11"
  region           = "europe-west1"

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"
    backup_configuration {
        enabled = true
    }
  }

  depends_on = [google_project_service.cloudsql-admin]
}

resource "google_sql_database" "database" {
  name     = "plausible"
  instance = google_sql_database_instance.instance.name
}

# access for WUG

resource "google_service_account" "plausible" {
  account_id   = "plausible"
  project      = var.gcp_project_id
  display_name = "Allows plausible to connect to Cloud SQL"
}

resource "google_project_iam_binding" "project" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  members = [
    "serviceAccount:${google_service_account.plausible.email}"
  ]
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.plausible.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[plausible/plausible]",
  ]
}
