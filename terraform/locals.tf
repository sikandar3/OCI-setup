data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_services" "osn" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_containerengine_node_pool_option" "images" {
  node_pool_option_id = "all"
  compartment_id      = var.tenancy_ocid
}

locals {
  ad_name = data.oci_identity_availability_domains.ads.availability_domains[0].name

  osn_service = data.oci_core_services.osn.services[0]

  child_compartments = {
    app     = { name = "${var.environment_compartment_name}-app", description = "Agentic OP test-mckensey app compartment (replica of cmp-ag-op-d-app)" }
    db      = { name = "${var.environment_compartment_name}-db", description = "Agentic OP test-mckensey database compartment (replica of cmp-ag-op-d-db)" }
    infra   = { name = "${var.environment_compartment_name}-infra", description = "Agentic OP test-mckensey infra compartment (replica of cmp-ag-op-d-infra)" }
    lb      = { name = "${var.environment_compartment_name}-lb", description = "Agentic OP test-mckensey load balancer compartment (replica of cmp-ag-op-d-lb)" }
    network = { name = "${var.environment_compartment_name}-network", description = "Agentic OP test-mckensey network compartment (replica of cmp-ag-op-d-network)" }
  }

  # Source VCN 10.129.101.0/25 is split into four /27s: app, lb, infra, db.
  subnet_cidrs = {
    app   = cidrsubnet(var.vcn_cidr, 2, 0)
    lb    = cidrsubnet(var.vcn_cidr, 2, 1)
    infra = cidrsubnet(var.vcn_cidr, 2, 2)
    db    = cidrsubnet(var.vcn_cidr, 2, 3)
  }

  subnet_dns_labels = {
    app   = "snagtmckapp"
    lb    = "snagtmcklb"
    infra = "snagtmckinf"
    db    = "snagtmckdb"
  }

  k8s_version_numeric = trimprefix(var.kubernetes_version, "v")

  oke_images = [
    for source in data.oci_containerengine_node_pool_option.images.sources : source
    if can(regex("OKE-${local.k8s_version_numeric}", source.source_name)) && can(regex("Oracle-Linux", source.source_name))
  ]

  latest_oke_image_name = try(
    sort([for img in local.oke_images : img.source_name])[length(local.oke_images) - 1],
    null
  )

  node_image_id = coalesce(
    var.node_image_id,
    try([for img in local.oke_images : img.image_id if img.source_name == local.latest_oke_image_name][0], null)
  )

  bucket_names = [
    "${var.name_prefix}-correspondence",
    "${var.name_prefix}-documents",
    "${var.name_prefix}-publications",
    "${var.name_prefix}-tasks",
  ]

  container_repos = [
    "agentic-cos-op-backend",
    "agentic-cos-op-frontend",
    "agentic-cos-op-qdrant",
    "agentic-cos-op-vault-init",
  ]

  hub_routes = [
    { destination = var.external_cidrs.apex_uat_adb, description = "Route to ADB UAT subnet" },
    { destination = var.external_cidrs.azure_gn, description = "Route to Azure through GN" },
    { destination = var.external_cidrs.hub_100, description = "Hub 100" },
    { destination = var.external_cidrs.hub_100_192, description = "Hub 100.192" },
    { destination = var.external_cidrs.hub_96_192, description = "Hub 96.192" },
    { destination = var.external_cidrs.hub_96_224, description = "Hub 96.224" },
    { destination = var.external_cidrs.apex_uat_lb, description = "Route to Apex UAT private LB subnet" },
    { destination = var.external_cidrs.azure_alt, description = "Azure alternate" },
    { destination = var.external_cidrs.srms_api, description = "SRMS Integration API (srms_api.npc.qa)" },
  ]
}
