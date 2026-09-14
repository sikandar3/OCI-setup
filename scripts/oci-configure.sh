#!/usr/bin/env bash
# Build ~/.oci/config and the private key file from OCI_CLI_* secrets.
# Runs on every boot (environment "start"). Safe when secrets are absent.
set -euo pipefail

OCI_DIR="$HOME/.oci"
CONFIG="$OCI_DIR/config"
KEY="$OCI_DIR/oci_api_key.pem"

missing=0
for v in OCI_CLI_USER OCI_CLI_TENANCY OCI_CLI_FINGERPRINT OCI_CLI_REGION OCI_CLI_KEY_CONTENT; do
  if [ -z "${!v:-}" ]; then
    echo "[oci-configure] $v is not set"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "[oci-configure] OCI_CLI_* secrets not fully provided; skipping ~/.oci/config generation."
  echo "[oci-configure] Add them in the Secrets panel, then start a new agent."
  exit 0
fi

mkdir -p "$OCI_DIR"
chmod 700 "$OCI_DIR"

# Materialize the private key from the secret (never printed).
printf '%s\n' "$OCI_CLI_KEY_CONTENT" > "$KEY"
chmod 600 "$KEY"

{
  echo "[DEFAULT]"
  echo "user=${OCI_CLI_USER}"
  echo "tenancy=${OCI_CLI_TENANCY}"
  echo "fingerprint=${OCI_CLI_FINGERPRINT}"
  echo "region=${OCI_CLI_REGION}"
  echo "key_file=${KEY}"
  if [ -n "${OCI_CLI_PASSPHRASE:-}" ]; then
    echo "pass_phrase=${OCI_CLI_PASSPHRASE}"
  fi
} > "$CONFIG"
chmod 600 "$CONFIG"

echo "[oci-configure] Wrote $CONFIG (profile DEFAULT, region ${OCI_CLI_REGION})."
