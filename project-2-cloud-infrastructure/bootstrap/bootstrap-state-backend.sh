#!/usr/bin/env bash
# ============================================================================
# bootstrap-state-backend.sh
# Provisions the Terraform remote-state backend for project-2 (out-of-band).
#
# WHY OUT-OF-BAND: Terraform needs a backend to store state, but the backend
# itself is infrastructure. Rather than have Terraform bootstrap-and-migrate
# into managing its own backend (circular, fragile during migration), we create
# it once with this idempotent script and treat it as shared platform infra that
# exists before any Terraform runs. See ADR-0007.
#
# IDEMPOTENT: safe to re-run; existing resources are detected and skipped.
# AUTH: requires `az login` with rights to create RG, storage, role assignments.
# ============================================================================
set -euo pipefail

# --- Configuration. MUST stay in sync with environments/dev/backend.hcl -----
LOCATION="${LOCATION:-westeurope}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
NAME_PREFIX="${NAME_PREFIX:-pep}"
NAME_SUFFIX="${NAME_SUFFIX:-ldc}"            # personal token for global uniqueness
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
SOFT_DELETE_DAYS="${SOFT_DELETE_DAYS:-14}"

RG_NAME="rg-${NAME_PREFIX}-tfstate-${ENVIRONMENT}"
SA_NAME="st${NAME_PREFIX}tfstate${ENVIRONMENT}${NAME_SUFFIX}"
TAGS=(Project=platform-engineering-portfolio Component=state-backend ManagedBy=bootstrap-script Environment="$ENVIRONMENT")

# --- Helpers ----------------------------------------------------------------
log()  { printf '\033[0;36m[bootstrap]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[  ok  ]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[ fail ]\033[0m %s\n' "$*" >&2; exit 1; }

# --- Pre-flight -------------------------------------------------------------
command -v az >/dev/null || fail "Azure CLI (az) not found."
az account show >/dev/null 2>&1 || fail "Not logged in. Run 'az login' first."

SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)
log "Subscription:    ${SUB_NAME} (${SUB_ID})"
log "Resource group:  ${RG_NAME}"
log "Storage account: ${SA_NAME}"
log "Container:       ${CONTAINER_NAME}"
echo

# --- 1. Resource group ------------------------------------------------------
if az group show --name "$RG_NAME" >/dev/null 2>&1; then
  ok "Resource group already exists."
else
  log "Creating resource group..."
  az group create --name "$RG_NAME" --location "$LOCATION" --tags "${TAGS[@]}" --output none
  ok "Resource group created."
fi

# --- 2. Storage account -----------------------------------------------------
if az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" >/dev/null 2>&1; then
  ok "Storage account already exists."
else
  AVAILABLE=$(az storage account check-name --name "$SA_NAME" --query nameAvailable -o tsv)
  [ "$AVAILABLE" = "true" ] || fail "Name '${SA_NAME}' is taken globally. Change NAME_SUFFIX."
  log "Creating storage account..."
  az storage account create \
    --name "$SA_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --min-tls-version TLS1_2 \
    --https-only true \
    --allow-blob-public-access false \
    --allow-shared-key-access true \
    --tags "${TAGS[@]}" \
    --output none
  ok "Storage account created."
fi

# --- 3. Blob versioning + soft delete (state recovery safety net) -----------
log "Configuring versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days "$SOFT_DELETE_DAYS" \
  --enable-container-delete-retention true \
  --container-delete-retention-days "$SOFT_DELETE_DAYS" \
  --output none
ok "Versioning + soft delete set (${SOFT_DELETE_DAYS} days)."

# --- 4. State container (via account key — avoids an RBAC propagation race) -
log "Creating state container..."
ACCOUNT_KEY=$(az storage account keys list --account-name "$SA_NAME" --resource-group "$RG_NAME" --query "[0].value" -o tsv)
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$SA_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --public-access off \
  --output none
ok "Container '${CONTAINER_NAME}' ready."

# --- 5. RBAC — current user gets data-plane access for AAD state ops ---------
log "Assigning 'Storage Blob Data Contributor' to current user..."
CURRENT_OID=$(az ad signed-in-user show --query id -o tsv)
SA_ID=$(az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" --query id -o tsv)
if az role assignment list --assignee "$CURRENT_OID" --scope "$SA_ID" \
     --role "Storage Blob Data Contributor" --query "[0].id" -o tsv | grep -q .; then
  ok "Role assignment already exists."
else
  az role assignment create \
    --assignee-object-id "$CURRENT_OID" \
    --assignee-principal-type User \
    --role "Storage Blob Data Contributor" \
    --scope "$SA_ID" \
    --output none
  ok "Role assigned (allow ~1-2 min for propagation)."
fi

# --- Done -------------------------------------------------------------------
echo
ok "State backend is ready."
cat <<EOF

Backend config (mirrored in environments/dev/backend.hcl):
  resource_group_name  = "${RG_NAME}"
  storage_account_name = "${SA_NAME}"
  container_name       = "${CONTAINER_NAME}"
  use_azuread_auth     = true

Each component sets only:  key = "<component>.tfstate"
Init a component with:     terraform init -backend-config=../backend.hcl
EOF
