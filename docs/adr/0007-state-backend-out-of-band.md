# 0007. Provision the Terraform state backend out-of-band

## Status
Accepted

## Context
Terraform stores state in a remote backend, but the backend (an Azure Storage
Account + blob container) is itself infrastructure. This is a chicken-and-egg
problem. Two patterns solve it:

1. **Bootstrap-and-migrate** — create the backend with local state, then migrate
   Terraform to manage its own backend. Circular, fragile during the one-time
   migration, and couples the foundation to a destroy-sensitive self-reference.
2. **Out-of-band provisioning** — create the backend once with a small idempotent
   script, document it, and treat it as shared platform infrastructure that
   exists before any Terraform runs. Components reference it.

We initially implemented (1), found the migration brittle and the self-management
awkward, and refactored to (2).

## Decision
Provision the state backend out-of-band via an idempotent Azure CLI script
(`bootstrap/bootstrap-state-backend.sh`). The backend is NOT managed by the
Terraform that stores state in it.

This is a scoped exception to ADR-0001 (AVM over custom Terraform). ADR-0001
governs workload infrastructure (networking, AKS, ACR), fully managed by Terraform
using AVM modules. The state backend is foundation, not workload.

Backend config is kept DRY via a shared `environments/dev/backend.hcl` partial
config; each component's `backend.tf` declares only its state `key` and
initializes with `terraform init -backend-config=../backend.hcl`.

## Consequences
**Positive**
- No chicken-and-egg, no migration step, no circular self-management.
- Foundation has zero dependency on a pre-1.0 module.
- The bootstrap script is version-controlled, idempotent, and documented.
- DRY backend config: a new component needs one `backend.tf` with one line.

**Negative**
- The backend is described in a shell script, not HCL. Mitigated by idempotency,
  documentation, and the fact that backend infra is intentionally static.
- The storage account name is hard-coded in `backend.hcl`; changing it means
  editing one file.
