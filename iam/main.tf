provider "google" {
  project = "${var.gcp_project_id}"
  region  = "${var.gcp_region}"
}

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

resource "google_service_account" "vault" {
  account_id   = "vault-sa"
  display_name = "Service Account for Vault"
}

resource "google_project_iam_custom_role" "vault_role" {
  role_id     = "vault_role"
  title       = "Vault Custom Role"
  description = "Custom IAM role for Vault"

  permissions = [
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeys.get",
    "resourcemanager.projects.get",
  ]
}

resource "google_project_iam_member" "vault_compute_admin" {
  role   = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.vault.email}"
}

resource "google_project_iam_member" "vault_custom_role" {
  role   = "${google_project_iam_custom_role.vault_role.id}"
  member = "serviceAccount:${google_service_account.vault.email}"
}
