# Architecture Decision Records

This directory contains the Architecture Decision Records (ADRs) for the
platform-engineering-portfolio project.

ADRs document significant architectural decisions with their context, rationale,
and consequences. They serve as a permanent record of *why* things are built
the way they are — not just *what* was built.

## Format

ADRs follow the [MADR](https://adr.github.io/madr/) (Markdown Architectural
Decision Records) format. See [template.md](template.md) for the structure.

## Index

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-use-avm-modules-over-custom.md) | Use AVM modules over custom Terraform | Accepted |
| [0002](0002-managed-node-pools-over-virtual-nodes.md) | Managed node pools over Virtual Nodes | Accepted |
| [0003](0003-github-oidc-over-long-lived-credentials.md) | GitHub OIDC over long-lived credentials | Accepted |
| [0004](0004-umbrella-helm-chart-with-subcharts.md) | Umbrella Helm chart with subcharts | Accepted |
| [0005](0005-terraform-to-terragrunt-refactor.md) | Terraform-to-Terragrunt refactor | Accepted |
| [0006](0006-online-boutique-as-demo-application.md) | Online Boutique as demo application | Accepted |

## Adding a new ADR

1. Copy `template.md` to `NNNN-short-title.md` (next sequential number)
2. Fill in all sections
3. Add the entry to the index table above
4. Reference the ADR from relevant project READMEs
