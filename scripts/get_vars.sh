#!/bin/sh
# ==============================================================================
# get_vars.sh - Load environment-specific tfvars files
# ==============================================================================
# Usage: terraform plan $(./scripts/get_vars.sh dev base-infrastructure)
#        terraform apply $(./scripts/get_vars.sh staging app-infrastructure)
# ==============================================================================

if [ -z "${1}" ] || [ -z "${2}" ]; then
  echo "Usage: $0 <environment> <layer>" >&2
  echo "  environment: dev, staging, prod" >&2
  echo "  layer: base-infrastructure, app-infrastructure" >&2
  exit 1
fi

ENV="${1}"
LAYER="${2}"
BASE_DIR="${LAYER}/inputs/${ENV}"

if [ ! -d "${BASE_DIR}" ]; then
  echo "Error: Directory '${BASE_DIR}' does not exist." >&2
  exit 1
fi

# Find all .tfvars files and construct -var-file arguments
find "${BASE_DIR}" \
  -name '*.tfvars' \
  -exec printf -- "-var-file=%s " "{}" +
