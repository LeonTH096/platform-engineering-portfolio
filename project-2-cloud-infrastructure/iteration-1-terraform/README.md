# Iteration 1 — Plain Terraform + AVM Modules

Azure Landing Zone using standard Terraform with Azure Verified Modules.

## Build order

1. `state-backend/` — Azure Storage Account + Blob Container for remote state
2. `identity/` — Managed Identity + GitHub OIDC federation
3. `networking/` — VNet, subnets, NSGs
4. `acr/` — Azure Container Registry
5. `aks/` — AKS cluster consuming the VNet and identity

Each component is a separate Terraform root module with its own state file,
connected via `terraform_remote_state` data sources.
