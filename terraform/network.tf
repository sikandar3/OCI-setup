resource "oci_core_vcn" "this" {
  compartment_id = oci_identity_compartment.child["network"].id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "vcn-${var.name_prefix}"
  dns_label      = var.vcn_dns_label
  freeform_tags  = var.freeform_tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "nat-${var.name_prefix}"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_service_gateway" "this" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sg-${var.name_prefix}"
  services {
    service_id = local.osn_service.id
  }
  freeform_tags = var.freeform_tags
}

resource "oci_core_drg_attachment" "this" {
  count        = var.attach_to_existing_drg ? 1 : 0
  display_name = "drg-attach-${var.name_prefix}"
  drg_id       = var.existing_drg_id
  network_details {
    id   = oci_core_vcn.this.id
    type = "VCN"
  }
}

# Default route table (infra / OKE API endpoint subnet), matching source.
resource "oci_core_default_route_table" "infra" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id
  display_name               = "Default Route Table for vcn-${var.name_prefix}"
  freeform_tags              = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    destination       = local.osn_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  dynamic "route_rules" {
    for_each = var.attach_to_existing_drg ? local.hub_routes : []
    content {
      destination       = route_rules.value.destination
      destination_type  = "CIDR_BLOCK"
      network_entity_id = var.existing_drg_id
      description       = route_rules.value.description
    }
  }
}

resource "oci_core_route_table" "app" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-${var.name_prefix}-app"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    destination       = local.osn_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  dynamic "route_rules" {
    for_each = var.attach_to_existing_drg ? local.hub_routes : []
    content {
      destination       = route_rules.value.destination
      destination_type  = "CIDR_BLOCK"
      network_entity_id = var.existing_drg_id
      description       = route_rules.value.description
    }
  }
}

resource "oci_core_route_table" "lb" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-${var.name_prefix}-lb"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.attach_to_existing_drg ? var.existing_drg_id : oci_core_nat_gateway.this.id
    description       = var.attach_to_existing_drg ? "Default via DRG (matches source ag-lb-app-rt)" : "Default via NAT (isolated test)"
  }

  dynamic "route_rules" {
    for_each = var.attach_to_existing_drg ? local.hub_routes : []
    content {
      destination       = route_rules.value.destination
      destination_type  = "CIDR_BLOCK"
      network_entity_id = var.existing_drg_id
      description       = route_rules.value.description
    }
  }
}

resource "oci_core_route_table" "db" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-${var.name_prefix}-db"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.attach_to_existing_drg ? var.existing_drg_id : oci_core_nat_gateway.this.id
  }

  route_rules {
    destination       = local.osn_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  dynamic "route_rules" {
    for_each = var.attach_to_existing_drg ? [
      { destination = var.external_cidrs.hub_100, description = "Hub 100" },
      { destination = var.external_cidrs.hub_96, description = "Hub 96" },
      { destination = var.external_cidrs.hub_100_192, description = "Hub 100.192" },
    ] : []
    content {
      destination       = route_rules.value.destination
      destination_type  = "CIDR_BLOCK"
      network_entity_id = var.existing_drg_id
      description       = route_rules.value.description
    }
  }
}

resource "oci_core_default_security_list" "vcn" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
  display_name               = "Default Security List for vcn-${var.name_prefix}"
  freeform_tags              = var.freeform_tags

  ingress_security_rules {
    protocol    = "1"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol    = "1"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "app" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-app"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    description = "All TCP from app subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "RDP for Secure Desktop from app subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 3389
      max = 3389
    }
  }

  ingress_security_rules {
    description = "HTTPS access from hub 96"
    protocol    = "6"
    source      = var.external_cidrs.hub_96
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    description = "RDP access from hub 96"
    protocol    = "6"
    source      = var.external_cidrs.hub_96
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 3389
      max = 3389
    }
  }

  ingress_security_rules {
    description = "All TCP from hub 96"
    protocol    = "6"
    source      = var.external_cidrs.hub_96
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "All traffic from hub 96.192"
    protocol    = "all"
    source      = var.external_cidrs.hub_96_192
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "SSH from infra subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    description = "All traffic from hub 99.128"
    protocol    = "all"
    source      = var.external_cidrs.hub_99_128
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "Allow all internal VCN traffic"
    protocol    = "all"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "Kubernetes API endpoint to worker nodes"
    protocol    = "6"
    source      = local.subnet_cidrs.infra
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "Kubernetes API endpoint to kubelet"
    protocol    = "6"
    source      = local.subnet_cidrs.infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    description = "Path MTU discovery from API endpoint"
    protocol    = "1"
    source      = local.subnet_cidrs.infra
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    description = "All TCP from load balancer subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.lb
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "Load balancer to worker node ports"
    protocol    = "6"
    source      = local.subnet_cidrs.lb
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  egress_security_rules {
    description      = "Allow all outbound traffic"
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "lb" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-lb"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    description = "From infra subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.infra
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "From app/worker subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "From Secure Desktop app port 80"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    description = "From Secure Desktop app port 443"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    description = "From Secure Desktop infra port 80"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    description = "From Secure Desktop infra port 443"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    description = "From hub db subnet port 80"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_db
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    description = "From hub db subnet port 443"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_db
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    description = "HTTPS from corporate 10.26.1.0/26"
    protocol    = "6"
    source      = var.external_cidrs.corp_10_26_1
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "infra" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-infra"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    description = "Worker nodes to Kubernetes API endpoint"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    description = "Worker nodes to Kubernetes API endpoint"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    description = "Path MTU discovery"
    protocol    = "1"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    description = "Worker nodes to Kubernetes API endpoint (all TCP)"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    description = "API access from Secure Desktop infra"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "oke_api" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-oke-apie"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol    = "1"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = local.osn_service.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "db" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-db"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_security_list" "postgres" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-pg"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    description = "From OKE worker node"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 5432
      max = 5432
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "redis" {
  compartment_id = oci_identity_compartment.child["network"].id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-${var.name_prefix}-redis"
  freeform_tags  = var.freeform_tags

  ingress_security_rules {
    description = "OCI Cache from db subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.db
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6379
      max = 6379
    }
  }

  ingress_security_rules {
    description = "OCI Cache from OKE worker subnet"
    protocol    = "6"
    source      = local.subnet_cidrs.app
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6379
      max = 6379
    }
  }

  ingress_security_rules {
    description = "OCI Cache from postgresql-cdp / Secure Desktop infra"
    protocol    = "6"
    source      = var.external_cidrs.secure_desktop_infra
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6379
      max = 6379
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "app" {
  compartment_id             = oci_identity_compartment.child["network"].id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = local.subnet_cidrs.app
  display_name               = "sn-${var.name_prefix}-app"
  dns_label                  = local.subnet_dns_labels.app
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.app.id
  security_list_ids = [
    oci_core_default_security_list.vcn.id,
    oci_core_security_list.app.id,
  ]
  freeform_tags = var.freeform_tags
}

resource "oci_core_subnet" "lb" {
  compartment_id             = oci_identity_compartment.child["network"].id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = local.subnet_cidrs.lb
  display_name               = "sn-${var.name_prefix}-lb"
  dns_label                  = local.subnet_dns_labels.lb
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.lb.id
  security_list_ids = [
    oci_core_default_security_list.vcn.id,
    oci_core_security_list.lb.id,
  ]
  freeform_tags = var.freeform_tags
}

resource "oci_core_subnet" "infra" {
  compartment_id             = oci_identity_compartment.child["network"].id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = local.subnet_cidrs.infra
  display_name               = "sn-${var.name_prefix}-infra"
  dns_label                  = local.subnet_dns_labels.infra
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_vcn.this.default_route_table_id
  security_list_ids = [
    oci_core_default_security_list.vcn.id,
    oci_core_security_list.oke_api.id,
    oci_core_security_list.infra.id,
  ]
  freeform_tags = var.freeform_tags
}

resource "oci_core_subnet" "db" {
  compartment_id             = oci_identity_compartment.child["network"].id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = local.subnet_cidrs.db
  display_name               = "sn-${var.name_prefix}-db"
  dns_label                  = local.subnet_dns_labels.db
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.db.id
  security_list_ids = [
    oci_core_default_security_list.vcn.id,
    oci_core_security_list.postgres.id,
    oci_core_security_list.redis.id,
    oci_core_security_list.db.id,
  ]
  freeform_tags = var.freeform_tags
}
