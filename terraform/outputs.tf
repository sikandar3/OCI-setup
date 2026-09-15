output "environment_compartment_id" {
  description = "OCID of cmp-ag-op-test-mckensey (or the configured environment compartment name)."
  value       = oci_identity_compartment.environment.id
}

output "child_compartment_ids" {
  description = "OCIDs of the app, db, infra, lb, and network child compartments."
  value       = { for k, c in oci_identity_compartment.child : k => c.id }
}

output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "subnet_ids" {
  value = {
    app   = oci_core_subnet.app.id
    lb    = oci_core_subnet.lb.id
    infra = oci_core_subnet.infra.id
    db    = oci_core_subnet.db.id
  }
}

output "oke_cluster_id" {
  value = oci_containerengine_cluster.this.id
}

output "oke_node_pool_id" {
  value = oci_containerengine_node_pool.this.id
}

output "redis_cluster_id" {
  value = oci_redis_redis_cluster.this.id
}

output "vault_id" {
  value = oci_kms_vault.this.id
}

output "master_key_id" {
  value = oci_kms_key.master.id
}

output "bucket_names" {
  value = [for b in oci_objectstorage_bucket.this : b.name]
}

output "container_repository_ids" {
  value = { for k, r in oci_artifacts_container_repository.this : k => r.id }
}

output "devops_project_id" {
  value = oci_devops_project.this.id
}

output "devops_repository_id" {
  value = oci_devops_repository.this.id
}

output "policy_id" {
  value = oci_identity_policy.this.id
}
