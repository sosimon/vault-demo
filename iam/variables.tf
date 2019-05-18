variable "gcp_project_id" {
  description = "The name of the GCP Project where all resources will be launched."
}

variable "gcp_region" {
  description = "The Region in which all GCP resources will be launched."
  default     = "us-west1"
}
