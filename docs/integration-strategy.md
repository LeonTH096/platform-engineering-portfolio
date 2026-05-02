# Integration Strategy

## Overview

This portfolio consists of two layered projects designed to integrate, not just coexist.

```
┌─────────────────────────────────────────────────┐
│  Project 1 — Platform Microservices             │
│  (Helm, CI/CD, Observability)                   │
│                                                 │
│  Consumes: AKS cluster, ACR, Managed Identity   │
├─────────────────────────────────────────────────┤
│  Project 2 — Cloud Infrastructure               │
│  (Terraform/Terragrunt Landing Zone)            │
│                                                 │
│  Produces: VNet, AKS, ACR, Identity, OIDC       │
└─────────────────────────────────────────────────┘
```

## Dependency pattern: Layered

Project 2 creates the foundation. Project 1 consumes it.

### What Project 2 produces (outputs)

- VNet ID and subnet IDs (for AKS node placement)
- AKS cluster name and resource group
- ACR login server URL (for image push/pull)
- Managed Identity client ID (for workload identity)
- State backend coordinates (for remote state references)

### What Project 1 consumes (inputs)

In Terraform (iteration 1): `terraform_remote_state` data sources
In Terragrunt (iteration 2): `dependency` blocks in `terragrunt.hcl`

### CI/CD integration

- Project 2 pipelines run first (infrastructure must exist before apps deploy)
- Project 1 pipelines depend on Project 2 outputs (AKS credentials, ACR URL)
- GitHub Actions workflow ordering enforced via `workflow_run` triggers or manual gates

### Observability integration

- Prometheus/Grafana deployed by Project 1 (Helm) onto AKS (created by Project 2)
- Infrastructure metrics (node CPU/memory) come from AKS metrics-server
- Application metrics (request rate, latency) come from Online Boutique service annotations
- Single Grafana instance monitors both infrastructure and application layers

## State management

Separate state files per component, all stored in the same Azure Storage Account:
- `project2-networking.tfstate`
- `project2-aks.tfstate`
- `project2-acr.tfstate`
- `project2-identity.tfstate`
- `project1-helm-releases.tfstate` (if Helm releases are managed via Terraform)

## Why layered, not independent

Independent projects (each creating their own VNet, AKS, etc.) would demonstrate
less architectural thinking. Layered integration shows:

1. Understanding of blast radius isolation (infra changes vs app changes)
2. State management across project boundaries
3. Output/input contracts between infrastructure and platform layers
4. Real-world pattern: platform team builds foundation, product teams consume it
