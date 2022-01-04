provider "google" {
  project = var.gcp_project_id
  version = "~> 3.23"
}

provider "google-beta" {
  alias   = "google-beta"
  project = var.gcp_project_id
  version = "~> 3.23"
}
