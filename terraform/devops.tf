resource "oci_ons_notification_topic" "devops" {
  compartment_id = oci_identity_compartment.child["infra"].id
  name           = "${var.name_prefix}-topic-01"
  description    = "DevOps notifications for ${var.name_prefix}"
  freeform_tags  = var.freeform_tags
}

resource "oci_devops_project" "this" {
  compartment_id = oci_identity_compartment.child["infra"].id
  name           = "${var.name_prefix}-devops-proj"
  description    = "Agentic OP test-mckensey DevOps project (replica of ag-op-d-devops-proj)"
  freeform_tags  = var.freeform_tags

  notification_config {
    topic_id = oci_ons_notification_topic.devops.id
  }
}

resource "oci_devops_repository" "this" {
  name            = "agentic-cos"
  project_id      = oci_devops_project.this.id
  repository_type = "HOSTED"
  description     = "Hosted replica of the agentic-cos source repository (empty until code is pushed)"
}
