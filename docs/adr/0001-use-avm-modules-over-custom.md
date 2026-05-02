# ADR-0001: Use Azure Verified Modules over custom Terraform modules

## Status

Accepted

## Date

2026-05-02

## Context

When building Azure infrastructure with Terraform, teams face a fundamental choice:
write custom modules from scratch for every resource, or compose infrastructure using
Azure Verified Modules (AVM) — Microsoft's official, community-maintained Terraform
modules published under the `Azure/` GitHub organization.

Custom modules give full control but require ongoing maintenance, testing, and
documentation. They duplicate work that the AVM community (backed by Microsoft
engineering) has already done, tested against real Azure API behavior, and continues
to maintain across provider version bumps.

Production experience at Sistemi (enterprise Azure hub-spoke architecture) confirmed
that AVM modules are production-grade: battle-tested, well-documented, regularly
updated, and used by thousands of organizations. Writing custom modules for the same
resources would be a step backward — a "toy project" pattern that doesn't reflect
how senior engineers build infrastructure.

## Decision

Use Azure Verified Modules (AVM) for all Azure resources where an AVM module exists.
Only write custom Terraform code for glue logic, composition, or resources not covered
by AVM.

Key modules:
- `Azure/avm-res-network-virtualnetwork` — VNet and subnets
- `Azure/avm-res-containerservice-managedcluster` — AKS
- `Azure/avm-res-containerregistry-registry` — ACR
- `Azure/avm-res-managedidentity-userassignedidentity` — Managed Identity
- `Azure/avm-res-storage-storageaccount` — Storage Account (state backend)

## Consequences

### Positive

- Faster development: modules handle resource complexity, edge cases, and defaults
- Production-grade: tested against real Azure API behavior by Microsoft engineers
- Maintained: security patches and provider updates handled upstream
- Demonstrates industry-standard practice to hiring managers
- Consistent with Sistemi production patterns (AVM + Terragrunt)

### Negative

- Less granular control over individual resource arguments (trade-off accepted)
- Module version upgrades may introduce breaking changes (mitigated by version pinning)
- Learning the module's input interface adds initial overhead

### Neutral

- Module source changes from iteration 1 (Terraform registry) to iteration 2
  (Terragrunt `tfr:///` source syntax), but the module itself stays identical

## References

- [Azure Verified Modules registry](https://registry.terraform.io/namespaces/Azure)
- [AVM GitHub organization](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork)
- [AVM documentation](https://azure.github.io/Azure-Verified-Modules/)
