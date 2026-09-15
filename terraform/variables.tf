variable "tenancy_ocid" {
  description = "Tenancy OCID (source: OCI_CLI_TENANCY)."
  type        = string
}

variable "user_ocid" {
  description = "API user OCID (source: OCI_CLI_USER)."
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint (source: OCI_CLI_FINGERPRINT)."
  type        = string
}

variable "private_key" {
  description = "PEM private key contents (source: OCI_CLI_KEY_CONTENT). Do not commit this value."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region identifier (source: OCI_CLI_REGION)."
  type        = string
}

variable "parent_compartment_id" {
  description = "Parent compartment for the new environment. Defaults to cmp-ag-op-main, the parent of cmp-ag-op-dev."
  type        = string
  default     = "ocid1.compartment.oc21..aaaaaaaaomwl34fblu32wcekxo5pakdqayzff5o7stge4fo2uhwusymfdp5a"
}

variable "name_prefix" {
  description = "Prefix applied to compartments and globally unique resource names."
  type        = string
  default     = "ag-op-test-mckensey"
}

variable "environment_compartment_name" {
  description = "Name of the new environment compartment (replica of cmp-ag-op-dev)."
  type        = string
  default     = "cmp-ag-op-test-mckensey"
}

variable "vcn_cidr" {
  description = "CIDR for the new VCN. Must not overlap existing VCNs if the DRG is attached. Source VCN uses 10.129.101.0/25."
  type        = string
  default     = "10.129.102.0/25"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN (max 15 characters)."
  type        = string
  default     = "vcnagtmck"
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version. Source cluster uses v1.36.1."
  type        = string
  default     = "v1.36.1"
}

variable "node_pool_size" {
  description = "Worker node count. Source node pool size is 2."
  type        = number
  default     = 2
}

variable "node_shape" {
  description = "Worker node shape. Source uses VM.Standard.E5.Flex."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "node_ocpus" {
  description = "OCPUs per flex worker node."
  type        = number
  default     = 4
}

variable "node_memory_in_gbs" {
  description = "Memory in GB per flex worker node."
  type        = number
  default     = 24
}

variable "node_image_id" {
  description = "Optional override for the OKE worker image OCID. Leave null to select the latest matching Oracle Linux OKE image."
  type        = string
  default     = null
}

variable "pods_cidr" {
  description = "Pod overlay CIDR (Flannel). Source uses 10.244.0.0/16."
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "Kubernetes services CIDR. Source uses 10.96.0.0/16."
  type        = string
  default     = "10.96.0.0/16"
}

variable "redis_node_count" {
  description = "OCI Cache node count. Source uses 1."
  type        = number
  default     = 1
}

variable "redis_node_memory_in_gbs" {
  description = "OCI Cache memory per node in GB. Source uses 2."
  type        = number
  default     = 2
}

variable "redis_software_version" {
  description = "OCI Cache software version. Source uses REDIS_7_0."
  type        = string
  default     = "REDIS_7_0"
}

variable "manage_group_name" {
  description = "IAM group granted manage access on the replica compartments. Source policy uses grp-agentic-dev-manage."
  type        = string
  default     = "grp-agentic-dev-manage"
}

variable "workload_namespace" {
  description = "Kubernetes namespace used in workload-identity policy statements."
  type        = string
  default     = "agentic-cos"
}

variable "workload_service_accounts" {
  description = "Kubernetes service accounts granted vault and object-storage access via workload identity."
  type        = list(string)
  default     = ["agentic-cos-backend-sa", "agentic-cos-worker-sa"]
}

variable "attach_to_existing_drg" {
  description = "If true, attach the new VCN to an existing DRG and install hub routes. Defaults to false to avoid CIDR conflicts with cmp-ag-op-dev."
  type        = bool
  default     = false
}

variable "existing_drg_id" {
  description = "DRG OCID used when attach_to_existing_drg is true. Source VCN attaches to the tenancy hub DRG."
  type        = string
  default     = null
}

variable "create_vault_secrets" {
  description = "Create vault secrets. Leave false until vault_secret_values is supplied at apply time."
  type        = bool
  default     = false
}

variable "vault_secret_names" {
  description = "Secret names to create (matches source vault). Used as for_each keys so values can stay sensitive."
  type        = set(string)
  default = [
    "LINKUP_API_KEY",
    "AZURE_OPENAI_API_KEY",
    "AZURE_DOC_INTEL_KEY",
  ]
}

variable "vault_secret_values" {
  description = "Map of secret name to plaintext value. Never commit real values."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "external_cidrs" {
  description = "On-prem / hub CIDRs referenced by the source security lists and route tables."
  type        = map(string)
  default = {
    secure_desktop_app   = "10.129.100.64/26"
    secure_desktop_infra = "10.129.100.192/26"
    secure_desktop_db    = "10.129.100.128/26"
    hub_96               = "10.129.96.0/24"
    hub_96_192           = "10.129.96.192/28"
    hub_96_224           = "10.129.96.224/28"
    hub_99_128           = "10.129.99.128/26"
    hub_100              = "10.129.100.0/24"
    hub_100_192          = "10.129.100.192/26"
    apex_uat_lb          = "10.129.98.0/26"
    apex_uat_adb         = "10.129.98.128/26"
    azure_gn             = "192.168.64.100/32"
    azure_alt            = "192.168.65.128/32"
    srms_api             = "192.168.8.10/32"
    corp_10_26_1         = "10.26.1.0/26"
    corp_10_26_1_lb      = "10.26.1.0/27"
  }
}

variable "freeform_tags" {
  description = "Freeform tags applied to supported resources."
  type        = map(string)
  default = {
    environment = "test"
    source      = "cmp-ag-op-dev"
    managed-by  = "terraform"
    project     = "ag-op-test-mckensey"
  }
}
