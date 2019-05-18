# Hashicorp Vault Demo

* Following instructions at https://github.com/hashicorp/terraform-google-vault

## Notes

* auto-unseal still requires `vault operator init` to be executed on a vault node
* iam module creates the `vault-sa` service account with proper [permissions](https://www.vaultproject.io/docs/configuration/seal/gcpckms.html)