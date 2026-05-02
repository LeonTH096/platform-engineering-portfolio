# ADR-0005: Terraform-to-Terragrunt refactor as explicit portfolio artifact

## Status

Accepted

## Date

2026-05-02

## Context

The cloud infrastructure project (Project 2) will be built twice: first with
plain Terraform, then refactored to Terragrunt. This is a deliberate portfolio
decision, not accidental duplication.

In production, teams rarely start with Terragrunt. They typically begin with
plain Terraform, encounter pain points as environments multiply (copy-pasted
backend blocks, duplicated variable definitions, manual dependency ordering),
and then migrate to Terragrunt to solve those specific problems.

The Sistemi project at work uses Terragrunt + AVM modules in production.
Leonardo already knows Terragrunt — the two-iteration approach isn't a
learning exercise, it's a demonstration of understanding *why* teams migrate.

## Decision

Build the Azure Landing Zone twice in the same repository:

- `iteration-1-terraform/` — Plain Terraform + AVM modules with standard
  backend configuration, `terraform_remote_state` data sources, and per-component
  `.tfvars` files
- `iteration-2-terragrunt/` — Same infrastructure refactored to Terragrunt with
  `root.hcl`, `dependency` blocks, and DRY input injection

Both iterations will coexist in the repo as a side-by-side comparison artifact.

## Consequences

### Positive

- Shows understanding of the Terraform → Terragrunt migration path
- Creates a concrete "before and after" that interviewers can review
- Demonstrates DRY principles: the diff between iterations IS the portfolio value
- Proves Terragrunt isn't just "another tool" but a solution to specific problems
- Aligns with Sistemi production experience (validates the pattern)

### Negative

- Doubles the infrastructure code surface area in the repository
- Both iterations must be kept in sync if the architecture changes
- Risk of confusion: which iteration is "the real one"? (mitigated by clear docs)

### Neutral

- Only iteration 2 (Terragrunt) will be wired to CI/CD pipelines — iteration 1
  is a reference implementation, not actively deployed

## References

- [Terragrunt documentation](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt vs Terraform](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/)
