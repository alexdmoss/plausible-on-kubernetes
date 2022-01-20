resource "google_storage_bucket" "velero" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = "EU"
  storage_class               = "MULTI_REGIONAL"
  uniform_bucket_level_access = true
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 15
    }
  }
}

resource "google_storage_bucket_iam_member" "velero_is_storage_object_viewer" {
  bucket = google_storage_bucket.velero.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_storage_bucket_iam_member" "velero_is_legacy_owner" {
  bucket = google_storage_bucket.velero.name
  role   = "roles/storage.legacyBucketOwner"
  member = "serviceAccount:${google_service_account.velero.email}"
}
