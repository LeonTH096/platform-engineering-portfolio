# Project 2 — Cloud Infrastructure

Azure Landing Zone built in two iterations: first with plain Terraform + AVM modules,
then refactored to Terragrunt — demonstrating the DRY evolution that production
infrastructure teams follow.

## Two-iteration approach

### Iteration 1: Plain Terraform + AVM modules

Standard Terraform with Azure Verified Modules. Establishes the foundation:
Azure Storage state backend, VNet, AKS, ACR, Managed Identity, and GitHub OIDC
federation.

### Iteration 2: Terragrunt + AVM modules

Same infrastructure, refactored to Terragrunt for DRY configuration management.
This mirrors the Sistemi production pattern (Terragrunt + AVM + Azure DevOps)
and demonstrates understanding of why teams migrate from Terraform to Terragrunt.

See [ADR-0005](../docs/adr/0005-terraform-to-terragrunt-refactor.md) for the full rationale.

## Structure

```
project-2-cloud-infrastructure/
├── iteration-1-terraform/
│   ├── environments/
│   │   └── dev/
│   │       ├── state-backend/     # Bootstrap: Azure Storage Account
│   │       ├── networking/        # VNet, subnets, NSGs
│   │       ├── aks/               # AKS cluster (system + user pools)
│   │       ├── acr/               # Azure Container Registry
│   │       └── identity/          # Managed Identity, OIDC federation
│   └── modules/                   # Thin composition wrappers (if needed)
├── iteration-2-terragrunt/
│   ├── environments/
│   │   └── dev/
│   │       ├── networking/
│   │       ├── aks/
│   │       ├── acr/
│   │       └── identity/
│   ├── root.hcl                   # Root Terragrunt config
│   └── common.hcl                 # Shared variables/locals
└── docs/                          # Project-specific documentation
```

## Key decisions

- [ADR-0001: AVM modules over custom Terraform](../docs/adr/0001-use-avm-modules-over-custom.md)
- [ADR-0003: GitHub OIDC over long-lived credentials](../docs/adr/0003-github-oidc-over-long-lived-credentials.md)
- [ADR-0005: Terraform-to-Terragrunt refactor](../docs/adr/0005-terraform-to-terragrunt-refactor.md)

## Status

🔲 Not started — this is Phase 1 (first to be built)
