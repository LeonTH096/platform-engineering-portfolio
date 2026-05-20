# State Backend Bootstrap

The Terraform remote-state backend for project-2 is **provisioned out-of-band**
by the idempotent script here — it is **not** managed by Terraform.
See [ADR-0007](../../docs/adr/0007-state-backend-out-of-band.md) for rationale.

## Creates
- Resource group `rg-pep-tfstate-dev` (isolated, long-lived)
- Storage account `stpeptfstatedevldc` (Standard_LRS, StorageV2, TLS 1.2,
  HTTPS-only, public blob access off)
- Blob container `tfstate` with versioning + 14-day soft delete
- `Storage Blob Data Contributor` for the running user (AAD state access)

## Usage
Requires `az login` with rights to create RGs, storage, and role assignments.

\```bash
az login
az account set --subscription "<subscription-id>"
./bootstrap-state-backend.sh
\```

Idempotent — re-running detects and skips existing resources.

## How components consume it (DRY backend)
Shared values live in `../iteration-1-terraform/environments/dev/backend.hcl`.
Each component declares only its own state key:

\```hcl
# environments/dev/networking/backend.tf
terraform {
  backend "azurerm" {
    key = "networking.tfstate"
  }
}
\```

Initialize with: `terraform init -backend-config=../backend.hcl`

## Teardown
`./teardown-state-backend.sh` deletes the backend and ALL stored state.
Only when the entire project is finished.
