resource "google_service_account" "velero" {
  account_id   = "velero"
  display_name = "Velero service account"
  project      = var.project_id
}

resource "google_project_iam_custom_role" "velero" {
  project = var.project_id
  role_id = "velero.server"
  title   = "Velero Server"

  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
  ]
}

resource "google_project_iam_member" "velero" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.velero.role_id}"
  member  = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero.name
}

resource "kubernetes_secret" "velero" {
  metadata {
    name      = "velero-cloud-credentials"
    namespace = var.namespace
  }

  data = {
    cloud = base64decode(google_service_account_key.velero.private_key)
  }
}
