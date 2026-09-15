resource "oci_objectstorage_bucket" "this" {
  for_each       = toset(local.bucket_names)
  compartment_id = oci_identity_compartment.child["infra"].id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = each.value
  access_type    = "NoPublicAccess"
  freeform_tags  = var.freeform_tags
}

resource "oci_artifacts_container_repository" "this" {
  for_each       = toset(local.container_repos)
  compartment_id = oci_identity_compartment.child["infra"].id
  display_name   = "${var.name_prefix}/${each.value}"
  is_public      = false
}
