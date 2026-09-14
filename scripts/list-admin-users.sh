#!/usr/bin/env bash
# List users who have tenancy-wide admin access.
#
# By default this reports members of the built-in "Administrators" group,
# which holds the default policy: Allow group Administrators to manage
# all-resources in tenancy. Pass a different group name as $1 to inspect
# a custom admin-like group.
set -euo pipefail

GROUP_NAME="${1:-Administrators}"

grp_id="$(oci iam group list --all \
  --query "data[?name=='${GROUP_NAME}'].id | [0]" --raw-output)"

if [ -z "$grp_id" ] || [ "$grp_id" = "null" ]; then
  echo "Group '${GROUP_NAME}' not found in this tenancy." >&2
  exit 1
fi

echo "Members of '${GROUP_NAME}' (group OCID: ${grp_id}):"
oci iam group list-users --group-id "$grp_id" --all \
  --output table \
  --query 'data[].{name:name, email:email, state:"lifecycle-state", id:id}'
