locals {
  policy_statements = concat(
    [
      "Allow group ${var.manage_group_name} to manage cluster-family in compartment id ${oci_identity_compartment.child["app"].id} where all {request.permission != 'CLUSTER_DELETE', request.permission != 'CLUSTER_NODE_POOL_DELETE', request.permission != 'CLUSTER_VIRTUAL_NODE_POOL_DELETE'}",
      "Allow group ${var.manage_group_name} to manage cluster-family in compartment id ${oci_identity_compartment.child["infra"].id} where all {request.permission != 'CLUSTER_DELETE', request.permission != 'CLUSTER_NODE_POOL_DELETE', request.permission != 'CLUSTER_VIRTUAL_NODE_POOL_DELETE'}",
      "Allow group ${var.manage_group_name} to manage instance-family in compartment id ${oci_identity_compartment.child["app"].id} where all {request.permission != 'INSTANCE_DELETE'}",
      "Allow group ${var.manage_group_name} to manage volume-family in compartment id ${oci_identity_compartment.child["app"].id} where all {request.permission != 'VOLUME_DELETE'}",
      "Allow group ${var.manage_group_name} to use virtual-network-family in compartment id ${oci_identity_compartment.child["network"].id}",
      "Allow group ${var.manage_group_name} to manage redis-family in compartment id ${oci_identity_compartment.child["db"].id} where all {request.operation != 'DeleteRedisCluster'}",
      "Allow group ${var.manage_group_name} to manage devops-family in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to use ons-topics in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to manage all-artifacts in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to manage object-family in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to manage vaults in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to manage keys in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow group ${var.manage_group_name} to manage secret-family in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow service objectstorage-${var.region} to manage object-family in compartment id ${oci_identity_compartment.child["infra"].id}",
      "Allow any-user to manage load-balancers in compartment id ${oci_identity_compartment.child["lb"].id} where ALL {request.principal.type = 'cluster', request.principal.id = '${oci_containerengine_cluster.this.id}'}",
      "Allow any-user to manage load-balancers in compartment id ${oci_identity_compartment.child["app"].id} where ALL {request.principal.type = 'cluster', request.principal.id = '${oci_containerengine_cluster.this.id}'}",
      "Allow any-user to manage instances in compartment id ${oci_identity_compartment.child["app"].id} where all { request.principal.id = '${oci_containerengine_cluster.this.id}' }",
      "Allow any-user to use private-ips in compartment id ${oci_identity_compartment.child["app"].id} where all { request.principal.id = '${oci_containerengine_cluster.this.id}' }",
    ],
    flatten([
      for sa in var.workload_service_accounts : [
        "Allow any-user to read secret-family in compartment id ${oci_identity_compartment.child["infra"].id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.workload_namespace}', request.principal.service_account = '${sa}', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}'}",
        "Allow any-user to manage objects in compartment id ${oci_identity_compartment.child["infra"].id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.workload_namespace}', request.principal.service_account = '${sa}', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}'}",
        "Allow any-user to read buckets in compartment id ${oci_identity_compartment.child["infra"].id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.workload_namespace}', request.principal.service_account = '${sa}', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}'}",
        "Allow any-user to manage buckets in compartment id ${oci_identity_compartment.child["infra"].id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.workload_namespace}', request.principal.service_account = '${sa}', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}', request.permission = 'PAR_MANAGE'}",
      ]
    ])
  )
}

resource "oci_identity_policy" "this" {
  compartment_id = var.tenancy_ocid
  name           = "${var.name_prefix}-pol"
  description    = "Replica of agentic-op-oke-dev-pol for ${var.environment_compartment_name}"
  statements     = local.policy_statements
  freeform_tags  = var.freeform_tags

  depends_on = [
    oci_identity_compartment.child,
    oci_containerengine_cluster.this,
  ]
}
