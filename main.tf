# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the vault-cluster module to deploy a private Vault cluster in GCP. A private Vault
# cluster is the recommended approach for production usage. This cluster uses Consul, running in a separate cluster, as
# its High Availability backend.
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = "${var.gcp_project_id}"
  region  = "${var.gcp_region}"
}

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE VAULT SERVER CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

data "google_compute_image" "image" {
  project = "${var.gcp_project_id}"
  family  = "vault-consul"
}

resource "random_id" "bucket" {
  byte_length = 4
}

module "vault_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  source = "git::git@github.com:hashicorp/terraform-google-vault.git//modules/vault-cluster?ref=1767c4bd7fc7b1f757c6e397d02ae70738d45515"

  subnetwork_name = "default"

  gcp_project_id = "${var.gcp_project_id}"
  gcp_region     = "${var.gcp_region}"

  cluster_name     = "${var.vault_cluster_name}"
  cluster_size     = "${var.vault_cluster_size}"
  cluster_tag_name = "${var.vault_cluster_name}"
  machine_type     = "${var.vault_cluster_machine_type}"

  source_image   = "${data.google_compute_image.image.name}"
  startup_script = "${data.template_file.startup_script_vault.rendered}"

  gcs_bucket_name          = "${var.vault_cluster_name}-${random_id.bucket.hex}"
  gcs_bucket_location      = "${var.gcs_bucket_location}"
  gcs_bucket_storage_class = "${var.gcs_bucket_class}"
  gcs_bucket_force_destroy = "${var.gcs_bucket_force_destroy}"

  root_volume_disk_size_gb = "${var.root_volume_disk_size_gb}"
  root_volume_disk_type    = "${var.root_volume_disk_type}"

  # Note that the only way to reach private nodes via SSH is to first SSH into another node that is not private.
  assign_public_ip_addresses = false

  # To enable external access to the Vault Cluster, enter the approved CIDR Blocks or tags below.
  # We enable health checks from the Consul Server cluster to Vault.
  allowed_inbound_cidr_blocks_api = []

  allowed_inbound_tags_api = ["${var.consul_server_cluster_name}"]
}

# Render the Startup Script that will run on each Vault Instance on boot. This script will configure and start Vault.
data "template_file" "startup_script_vault" {
  template = "${file("${path.module}/startup-script-vault.sh")}"

  vars {
    consul_cluster_tag_name = "${var.consul_server_cluster_name}"
    vault_cluster_tag_name  = "${var.vault_cluster_name}"
    enable_vault_ui         = "${var.enable_vault_ui ? "--enable-ui" : ""}"
  }
}
