check "oke_node_image" {
  assert {
    condition     = local.node_image_id != null
    error_message = "No OKE node image matched Kubernetes ${var.kubernetes_version}. Set node_image_id."
  }
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = oci_identity_compartment.child["app"].id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name_prefix}-oke-cls-01"
  vcn_id             = oci_core_vcn.this.id
  type               = "ENHANCED_CLUSTER"
  freeform_tags      = var.freeform_tags

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = oci_core_subnet.infra.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.lb.id]

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
  }
}

resource "oci_containerengine_node_pool" "this" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = oci_identity_compartment.child["app"].id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name_prefix}-npool-01"
  node_shape         = var.node_shape
  freeform_tags      = var.freeform_tags

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_in_gbs
  }

  node_source_details {
    image_id    = local.node_image_id
    source_type = "IMAGE"
  }

  initial_node_labels {
    key   = "name"
    value = "${var.name_prefix}-npool-01"
  }

  node_config_details {
    size = var.node_pool_size

    placement_configs {
      availability_domain = local.ad_name
      subnet_id           = oci_core_subnet.app.id
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  node_eviction_node_pool_settings {
    eviction_grace_duration              = "PT1H"
    is_force_delete_after_grace_duration = false
  }
}
