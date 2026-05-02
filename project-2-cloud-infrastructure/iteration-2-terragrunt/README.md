# Iteration 2 — Terragrunt + AVM Modules

Same infrastructure as Iteration 1, refactored to Terragrunt for DRY
configuration management.

## What changes

- Per-component `terragrunt.hcl` files replace `main.tf` + `variables.tf` + `backend.tf`
- `root.hcl` centralizes provider config, backend config, and common tags
- `dependency` blocks replace `terraform_remote_state` data sources
- Environment-specific values are injected via `inputs = {}` instead of `.tfvars`

## What stays the same

- Same AVM modules (same versions, same inputs)
- Same Azure resources created
- Same state files in the same Azure Storage backend

This side-by-side comparison is the portfolio artifact — it shows the "before and after"
of a real Terragrunt migration.
