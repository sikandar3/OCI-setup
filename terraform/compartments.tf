resource "oci_identity_compartment" "environment" {
  compartment_id = var.parent_compartment_id
  name           = var.environment_compartment_name
  description    = "Replica of cmp-ag-op-dev for McKinsey test"
  enable_delete  = true
  freeform_tags  = var.freeform_tags
}

resource "oci_identity_compartment" "child" {
  for_each       = local.child_compartments
  compartment_id = oci_identity_compartment.environment.id
  name           = each.value.name
  description    = each.value.description
  enable_delete  = true
  freeform_tags  = var.freeform_tags
}
