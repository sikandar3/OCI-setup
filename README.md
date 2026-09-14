# OCI-setup

Cloud Agent environment for working with **Oracle Cloud Infrastructure (OCI)** via the
OCI CLI, authenticated with an API key.

## What the environment does

The Cloud Agent environment (`.cursor/environment.json`) is wired to authenticate
automatically from environment secrets:

- **`install`** (`scripts/install.sh`) — installs the OCI CLI and puts `oci` on the PATH.
- **`start`** (`scripts/oci-configure.sh`) — on every boot, builds `~/.oci/config` and the
  private key file from the `OCI_CLI_*` secrets. If the secrets aren't set, it skips
  gracefully.

## Required secrets

Add these in the Cursor **Secrets** panel (never commit them). They map to the values in
your OCI Console API-key "Configuration File Preview":

| Secret | Value |
| --- | --- |
| `OCI_CLI_USER` | user OCID (`ocid1.user.oc1..`) |
| `OCI_CLI_TENANCY` | tenancy OCID (`ocid1.tenancy.oc1..`) |
| `OCI_CLI_FINGERPRINT` | API key fingerprint |
| `OCI_CLI_REGION` | region identifier, e.g. `me-dcc-doha-1` |
| `OCI_CLI_KEY_CONTENT` | full PEM text of the private key |
| `OCI_CLI_PASSPHRASE` | *(optional)* passphrase, only if the key is encrypted |

Secrets are injected into **new** Cloud Agent VMs, so add them and then start a fresh agent.

## Verify login

```bash
oci iam region list --output table
oci os ns get
```

## List users with admin access

```bash
bash scripts/list-admin-users.sh
# or inspect a custom admin-like group:
bash scripts/list-admin-users.sh MyAdminGroup
```

This reports members of the built-in `Administrators` group (default full-admin access).
To catch custom groups that were granted `manage all-resources`, scan policies:

```bash
oci iam policy list --compartment-id <tenancy-ocid> --all \
  --query "data[].statements[?contains(@,'manage all-resources')] | []" --output json
```
