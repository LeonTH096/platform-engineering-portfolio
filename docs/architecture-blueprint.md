# Architecture Blueprint

> Full blueprint will be generated in a subsequent step.
> This document will contain the complete system design, component specifications,
> timeline, cost estimates, and specific interview talking points.

## Quick reference

- **Cloud:** Azure (AKS, ACR, VNet, Managed Identity, Azure Storage)
- **IaC:** Terraform → Terragrunt (AVM modules)
- **Application:** Google Online Boutique (11 microservices)
- **CI/CD:** GitHub Actions with OIDC authentication
- **Observability:** Prometheus + Grafana (kube-prometheus-stack)
- **Helm:** Umbrella chart with subcharts

## Project structure

```
platform-engineering-portfolio/
├── project-1-platform-microservices/     # Helm, K8s, CI/CD, observability
├── project-2-cloud-infrastructure/       # Terraform/Terragrunt landing zone
│   ├── iteration-1-terraform/            # Plain Terraform + AVM
│   └── iteration-2-terragrunt/           # Terragrunt refactor
└── docs/                                 # ADRs, blueprint, integration strategy
```
