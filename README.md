# Platform Engineering Portfolio

Production-grade Azure infrastructure portfolio demonstrating platform engineering
competency: AKS cluster on a Terraform/Terragrunt landing zone, 11-service
microservices deployment via Helm, GitHub Actions CI/CD with OIDC authentication,
and Prometheus/Grafana observability.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                          │
│              (OIDC federation — no stored secrets)               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Project 1 — Platform Microservices                        │  │
│  │                                                            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │  │
│  │  │ frontend │ │ cart     │ │ checkout │ │ payment  │ ... │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │  │
│  │  Google Online Boutique (11 services) via Helm umbrella   │  │
│  │                                                            │  │
│  │  ┌─────────────────────┐  ┌────────────────────────────┐  │  │
│  │  │ Prometheus + Grafana │  │ HPA, PDB, Network Policies │  │  │
│  │  └─────────────────────┘  └────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                          ▲ consumes                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Project 2 — Cloud Infrastructure (Azure Landing Zone)     │  │
│  │                                                            │  │
│  │  ┌────────┐ ┌─────┐ ┌─────┐ ┌──────────┐ ┌────────────┐ │  │
│  │  │  VNet  │ │ AKS │ │ ACR │ │ Identity │ │ Storage    │ │  │
│  │  └────────┘ └─────┘ └─────┘ └──────────┘ └────────────┘ │  │
│  │                                                            │  │
│  │  Iteration 1: Terraform + AVM    ──►    Iteration 2: Terragrunt + AVM │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Projects

### [Project 1 — Platform Microservices](project-1-platform-microservices/)

Deploys [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo)
(11-service polyglot microservices demo) on AKS with production-grade Kubernetes patterns.

**Scope:** Helm umbrella chart with subcharts, GitHub Actions CI/CD, HPA autoscaling,
PodDisruptionBudgets, Network Policies, Prometheus + Grafana observability stack.

### [Project 2 — Cloud Infrastructure](project-2-cloud-infrastructure/)

Azure Landing Zone built in two iterations demonstrating the Terraform → Terragrunt
evolution that production infrastructure teams follow.

**Scope:** VNet, AKS (system + user node pools), ACR, Managed Identity with Workload
Identity, GitHub OIDC federation, Azure Storage state backend — all using
[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/).

## Technology stack

| Layer | Tools |
|-------|-------|
| **Cloud** | Azure (AKS, ACR, VNet, Managed Identity, Azure Storage) |
| **IaC** | Terraform → Terragrunt with Azure Verified Modules (AVM) |
| **Containers** | Docker, AKS (managed node pools with Cluster Autoscaler) |
| **Packaging** | Helm 4.x (umbrella chart with subcharts) |
| **CI/CD** | GitHub Actions with OIDC authentication (zero stored secrets) |
| **Observability** | Prometheus, Grafana (kube-prometheus-stack) |
| **Application** | Google Online Boutique (11 microservices) |

## Architecture decisions

Key technical decisions are documented as Architecture Decision Records (ADRs):

| Decision | Summary |
|----------|---------|
| [ADR-0001](docs/adr/0001-use-avm-modules-over-custom.md) | AVM modules over custom Terraform — production pattern, not reinventing the wheel |
| [ADR-0002](docs/adr/0002-managed-node-pools-over-virtual-nodes.md) | Managed node pools over Virtual Nodes — demonstrate node-level operations |
| [ADR-0003](docs/adr/0003-github-oidc-over-long-lived-credentials.md) | GitHub OIDC over long-lived credentials — zero-trust CI/CD authentication |
| [ADR-0004](docs/adr/0004-umbrella-helm-chart-with-subcharts.md) | Umbrella Helm chart with subcharts — mirrors multi-team service ownership |
| [ADR-0005](docs/adr/0005-terraform-to-terragrunt-refactor.md) | Terraform → Terragrunt refactor — explicit DRY evolution as portfolio artifact |
| [ADR-0006](docs/adr/0006-online-boutique-as-demo-application.md) | Online Boutique as demo app — 100% infrastructure focus for a platform role |

## Repository structure

```
platform-engineering-portfolio/
├── project-1-platform-microservices/
│   ├── helm/online-boutique/          # Umbrella Helm chart (11 subcharts)
│   ├── kubernetes/                    # Raw manifests (if needed)
│   └── docs/
├── project-2-cloud-infrastructure/
│   ├── iteration-1-terraform/         # Plain Terraform + AVM modules
│   │   └── environments/dev/          # state-backend, networking, aks, acr, identity
│   ├── iteration-2-terragrunt/        # Terragrunt refactor + AVM modules
│   │   └── environments/dev/          # Same components, DRY configuration
│   └── docs/
├── docs/
│   ├── adr/                           # Architecture Decision Records
│   ├── architecture-blueprint.md      # Complete system design
│   └── integration-strategy.md        # How projects connect
└── .github/
    └── workflows/                     # CI/CD pipeline definitions
```

## Design philosophy

This portfolio follows three principles:

**Production patterns, not toy projects.** Every component uses the same tools and
patterns that production infrastructure teams use: official cloud provider modules
(AVM), DRY configuration management (Terragrunt), OIDC-based authentication,
and structured observability. Nothing is built from scratch when a battle-tested
module exists.

**Depth over breadth.** Rather than touching 15 tools superficially, this portfolio
goes deep on the core platform engineering stack: IaC, Kubernetes, CI/CD, and
observability. Each layer is implemented with production-grade patterns and
documented with explicit architectural reasoning.

**Integration by design.** The two projects are designed to layer together from day
one — not built independently and stitched together after the fact. Project 2
produces infrastructure outputs that Project 1 consumes, mirroring how platform
teams build foundations that product teams deploy onto.

## Status

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Azure Landing Zone — state backend, networking, AKS, ACR, identity | 🔲 Not started |
| Phase 2 | Helm charts — umbrella chart, subcharts, values per environment | 🔲 Not started |
| Phase 3 | CI/CD — GitHub Actions pipelines for Terraform + Helm | 🔲 Not started |
| Phase 4 | Observability — Prometheus, Grafana, alerting rules | 🔲 Not started |
| Phase 5 | Terragrunt refactor — DRY migration of iteration 1 | 🔲 Not started |

## License

[MIT](LICENSE)
