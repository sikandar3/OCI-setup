# OCI-setup

Terraform for an isolated replica of the Agentic OP **dev** compartment tree lives in [`terraform/`](terraform/).

It creates `cmp-ag-op-test-mckensey` (under `cmp-ag-op-main`) with networking, OKE, OCI Cache, vault, storage, DevOps, and IAM modeled on live `cmp-ag-op-dev`.

