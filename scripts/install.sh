#!/usr/bin/env bash
# Idempotent install of the OCI CLI for the Cloud Agent environment.
# Runs after checkout; safe to run repeatedly.
set -euo pipefail

VENV_OCI="$HOME/lib/oracle-cli/bin/oci"

if [ ! -x "$VENV_OCI" ] && ! command -v oci >/dev/null 2>&1; then
  echo "[install] Installing OCI CLI..."
  curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -o /tmp/oci_install.sh
  bash /tmp/oci_install.sh --accept-all-defaults
else
  echo "[install] OCI CLI already installed; skipping download."
fi

# Expose `oci` on the global PATH so every shell/agent finds it.
if [ -x "$VENV_OCI" ]; then
  sudo ln -sf "$VENV_OCI" /usr/local/bin/oci
fi

oci --version
echo "[install] OCI CLI ready."
