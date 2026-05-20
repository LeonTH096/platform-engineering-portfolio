#!/usr/bin/env bash
# teardown-state-backend.sh — DESTRUCTIVE. Deletes the backend RG and ALL
# Terraform state stored in it. Only use when the whole project is finished.
set -euo pipefail
NAME_PREFIX="${NAME_PREFIX:-pep}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
RG_NAME="rg-${NAME_PREFIX}-tfstate-${ENVIRONMENT}"

read -rp "This DELETES ${RG_NAME} and ALL state in it. Type the RG name to confirm: " CONFIRM
[ "$CONFIRM" = "$RG_NAME" ] || { echo "Aborted."; exit 1; }
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deletion started for ${RG_NAME}."
