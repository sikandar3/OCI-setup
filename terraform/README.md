# Terraform replica of cmp-ag-op-dev

This stack creates `cmp-ag-op-test-mckensey` under `cmp-ag-op-main` and recreates the Agentic OP **dev** topology discovered in the tenancy: child compartments, VCN, security lists, OKE, OCI Cache (Redis), vault, buckets, OCIR repos, DevOps, and IAM.

It is a **create-new** replica, not an import of the live `cmp-ag-op-dev` resources.

## Source mapping

| Source (`cmp-ag-op-dev`) | This stack |
| --- | --- |
| `cmp-ag-op-dev` | `cmp-ag-op-test-mckensey` |
| `cmp-ag-op-d-app` | `cmp-ag-op-test-mckensey-app` |
| `cmp-ag-op-d-db` | `cmp-ag-op-test-mckensey-db` |
| `cmp-ag-op-d-infra` | `cmp-ag-op-test-mckensey-infra` |
| `cmp-ag-op-d-lb` | `cmp-ag-op-test-mckensey-lb` |
| `cmp-ag-op-d-network` (empty; VCN lived in `cmp-ag-d-network`) | `cmp-ag-op-test-mckensey-network` **with the VCN inside it** |
| VCN `vcn-drccnpc1-ag-dev` `10.129.101.0/25` | `vcn-ag-op-test-mckensey` default `10.129.102.0/25` |
| OKE `dev-ag-op-oke-cls-01` + node pool size 2 | `${name_prefix}-oke-cls-01` + matching node pool |
| Redis `ag-op-d-redis-cls-01` | `${name_prefix}-redis-cls-01` |
| Vault / AES HSM key / secret names | New vault and key; secret **values** are not copied |
| Buckets `ag-op-*` | Prefixed names (tenancy-unique) |
| OCIR repos `agentic-cos-op-*` | Prefixed path `${name_prefix}/agentic-cos-op-*` |
| Policy `agentic-op-oke-dev-pol` | `${name_prefix}-pol` bound to the new cluster OCID |

### Intentionally not copied

- Worker instances, boot volumes, and CSI volumes — created by the OKE node pool and in-cluster storage.
- Kubernetes LoadBalancer `521b8df1-...` — created by the OKE cloud controller when you deploy the Service.
- Redis private DNS zones — created by OCI Cache.
- Log Analytics entities — auto-ingested.
- Container image layers and DevOps git contents — copy with `docker push` / `git push` after apply.
- Secret plaintext — pass with `TF_VAR_vault_secret_values` at apply time.

## Prerequisites

- Terraform >= 1.6
- OCI API key with rights to manage identity, networking, OKE, Redis, KMS, Object Storage, Artifacts, DevOps, and policies in the tenancy
- An unused VCN CIDR if this will run alongside `cmp-ag-op-dev`

## Configure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

export TF_VAR_tenancy_ocid="$OCI_CLI_TENANCY"
export TF_VAR_user_ocid="$OCI_CLI_USER"
export TF_VAR_fingerprint="$OCI_CLI_FINGERPRINT"
export TF_VAR_region="$OCI_CLI_REGION"
export TF_VAR_private_key="$OCI_CLI_KEY_CONTENT"
```

Edit `terraform.tfvars` for CIDR, node size, or DRG attachment. Do not commit `terraform.tfvars` or secret values.

## Plan and apply

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

OKE node pool creation can take 15–25 minutes.

To attach this VCN to the existing hub DRG (source behavior), set `attach_to_existing_drg = true` and `existing_drg_id` **only after** confirming `vcn_cidr` does not overlap `10.129.101.0/25` or other hub routes.

## Customize

All tunables live in `variables.tf`. Common ones:

- `vcn_cidr` / `external_cidrs` — networking and security-list sources
- `kubernetes_version`, `node_pool_size`, `node_shape`
- `manage_group_name` — IAM group from the source policy
- `vault_secret_values` — populate `LINKUP_API_KEY`, `AZURE_OPENAI_API_KEY`, `AZURE_DOC_INTEL_KEY`

## After apply

1. Push application images into the new OCIR repositories.
2. Push `agentic-cos` source into the new DevOps repository.
3. Deploy the Kubernetes workloads; OKE will create the private Load Balancer in the LB subnet.
4. Store real API keys in the vault if they were not passed into Terraform.

