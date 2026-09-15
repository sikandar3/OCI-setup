resource "oci_redis_redis_cluster" "this" {
  compartment_id     = oci_identity_compartment.child["db"].id
  display_name       = "${var.name_prefix}-redis-cls-01"
  node_count         = var.redis_node_count
  node_memory_in_gbs = var.redis_node_memory_in_gbs
  software_version   = var.redis_software_version
  subnet_id          = oci_core_subnet.db.id
  cluster_mode       = "NONSHARDED"
  freeform_tags      = var.freeform_tags
}
