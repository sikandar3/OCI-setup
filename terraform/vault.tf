resource "oci_kms_vault" "this" {
  compartment_id = oci_identity_compartment.child["infra"].id
  display_name   = "${var.name_prefix}-vault"
  vault_type     = "DEFAULT"
  freeform_tags  = var.freeform_tags
}

resource "oci_kms_key" "master" {
  compartment_id      = oci_identity_compartment.child["infra"].id
  display_name        = "${var.name_prefix}-mkey"
  management_endpoint = oci_kms_vault.this.management_endpoint
  protection_mode     = "HSM"
  freeform_tags       = var.freeform_tags

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "this" {
  for_each = var.create_vault_secrets ? var.vault_secret_names : toset([])

  compartment_id = oci_identity_compartment.child["infra"].id
  secret_name    = each.key
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.master.id
  freeform_tags  = var.freeform_tags

  secret_content {
    content_type = "BASE64"
    content      = base64encode(lookup(var.vault_secret_values, each.key, ""))
  }
}
