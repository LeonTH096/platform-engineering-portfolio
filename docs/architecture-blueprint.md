# Architecture Blueprint

Complete system design for the Platform Engineering Portfolio.

## Table of contents

- [Overview](#overview)
- [Project 1 — Platform Microservices](#project-1--platform-microservices)
- [Project 2 — Cloud Infrastructure](#project-2--cloud-infrastructure)
- [Integration architecture](#integration-architecture)
- [CI/CD pipeline design](#cicd-pipeline-design)
- [Observability strategy](#observability-strategy)
- [Security model](#security-model)
- [Cost management](#cost-management)
- [Timeline and phases](#timeline-and-phases)
- [Interview talking points](#interview-talking-points)

---

## Overview

Two layered projects in a monorepo, designed to demonstrate platform engineering
competency at production depth.

**Project 2 (Cloud Infrastructure)** builds the Azure foundation: VNet, AKS cluster,
ACR registry, managed identities, and OIDC federation. Built first with plain
Terraform + AVM modules, then refactored to Terragrunt.

**Project 1 (Platform Microservices)** deploys Google Online Boutique (11 services)
onto the AKS cluster using a Helm umbrella chart, with GitHub Actions CI/CD and
Prometheus/Grafana observability.

The integration is layered by design: Project 2 produces infrastructure outputs
that Project 1 consumes via `terraform_remote_state` (iteration 1) or Terragrunt
`dependency` blocks (iteration 2).

---

## Project 1 — Platform Microservices

### Application: Google Online Boutique

11-service polyglot microservices demo chosen deliberately to maximize infrastructure
focus. See [ADR-0006](adr/0006-online-boutique-as-demo-application.md).

Services: frontend, cartservice, productcatalogservice, currencyservice,
paymentservice, shippingservice, emailservice, checkoutservice,
recommendationservice, adservice, redis-cart.

### Helm chart design

Umbrella chart with subcharts. See [ADR-0004](adr/0004-umbrella-helm-chart-with-subcharts.md).

```
helm/online-boutique/
├── Chart.yaml                    # Declares subchart dependencies
├── values.yaml                   # Base values (dev defaults)
├── values-prod.yaml              # Production overrides (if added later)
├── charts/
│   ├── frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── hpa.yaml
│   │       ├── pdb.yaml
│   │       └── networkpolicy.yaml
│   ├── cartservice/
│   │   └── ...                   # Same template structure
│   └── ... (9 more services)
└── templates/
    ├── _helpers.tpl              # Shared template helpers
    └── namespace.yaml            # Namespace creation
```

Each subchart includes:
- **Deployment** with resource requests/limits, liveness/readiness probes
- **Service** (ClusterIP for internal, LoadBalancer for frontend)
- **HPA** (Horizontal Pod Autoscaler) scaling on CPU/memory
- **PDB** (PodDisruptionBudget) ensuring availability during node drain
- **NetworkPolicy** restricting inter-service traffic to declared dependencies

### Kubernetes patterns demonstrated

| Pattern | Implementation | Why it matters |
|---------|---------------|----------------|
| Resource management | requests/limits on every container | Prevents noisy neighbors, enables HPA |
| Autoscaling | HPA per service (CPU target 70%) | Handles load spikes without over-provisioning |
| Disruption budgets | PDB with minAvailable on critical services | Safe node drain during cluster upgrades |
| Network segmentation | NetworkPolicy per service | Zero-trust: only declared traffic flows allowed |
| Health checks | Liveness + readiness probes per service | Automatic restart of unhealthy pods, traffic routing |
| Configuration | ConfigMaps for env-specific values | Clean separation of config from code |
| Secrets | Kubernetes Secrets (Sealed Secrets as stretch goal) | Credential management without plaintext in Git |
| Node affinity | User pool node selector on app workloads | Separation from system pool (CoreDNS, metrics-server) |

---

## Project 2 — Cloud Infrastructure

### Azure services

All provisioned via Azure Verified Modules (AVM). See [ADR-0001](adr/0001-use-avm-modules-over-custom.md).

| Service | AVM module | Purpose |
|---------|-----------|---------|
| Azure Storage Account | `avm-res-storage-storageaccount` | Terraform state backend |
| Virtual Network | `avm-res-network-virtualnetwork` | Network foundation (2 subnets minimum) |
| AKS Managed Cluster | `avm-res-containerservice-managedcluster` | Kubernetes cluster |
| Container Registry | `avm-res-containerregistry-registry` | Docker image storage |
| User-Assigned Managed Identity | `avm-res-managedidentity-userassignedidentity` | Workload Identity for pods |
| Resource Group | Native `azurerm_resource_group` | Logical grouping (not an AVM module) |

### Networking design

```
VNet: 10.0.0.0/16
├── aks-system-subnet:  10.0.1.0/24   (system node pool)
├── aks-user-subnet:    10.0.2.0/24   (user node pool — app workloads)
└── aks-pods-subnet:    10.0.3.0/22   (Azure CNI overlay pod CIDR — optional)
```

NSG rules:
- AKS system subnet: allow AKS control plane traffic, deny all else inbound
- AKS user subnet: allow internal cluster traffic, deny direct internet inbound
- Egress: allow all (AKS needs outbound for image pulls, Azure API calls)

### AKS cluster specification

See [ADR-0002](adr/0002-managed-node-pools-over-virtual-nodes.md).

| Setting | Value | Rationale |
|---------|-------|-----------|
| Kubernetes version | 1.31.x | Matches kubectl pin in devops-workstation-setup |
| System pool | 1 node, Standard_D2s_v3 | Minimal for CoreDNS, kube-proxy, metrics-server |
| System pool taint | CriticalAddonsOnly=true:NoSchedule | Prevents app scheduling on system nodes |
| User pool | 1-3 nodes, Standard_D4s_v3 | Online Boutique (11 services) + observability stack |
| User pool autoscaling | Enabled (min 1, max 3) | Cluster Autoscaler demonstration |
| Network plugin | Azure CNI | Production standard, required for Network Policies |
| Network policy | Calico | Enforces NetworkPolicy resources (Azure default) |
| Workload Identity | Enabled | Pod-level Azure authentication without secrets |
| OIDC issuer | Enabled | Required for Workload Identity federation |

Cost note: Standard_D2s_v3 ≈ €0.10/hr, Standard_D4s_v3 ≈ €0.20/hr. With 1+1
minimum nodes, idle cluster cost ≈ €0.30/hr. All resources destroyed after each
session — zero ongoing cost.

### State management

Azure Storage Account created by a bootstrap Terraform module (the only module
that uses local state initially, then migrates to remote).

State file separation:
```
Container: tfstate
├── state-backend.tfstate        # Bootstrap (chicken-and-egg: starts local)
├── networking.tfstate
├── identity.tfstate
├── acr.tfstate
└── aks.tfstate
```

Each component has its own state file for blast radius isolation: a networking
change can't accidentally destroy the AKS cluster because they're in different
state files.

### Terraform → Terragrunt migration

See [ADR-0005](adr/0005-terraform-to-terragrunt-refactor.md).

What changes in iteration 2:
- `backend {}` blocks removed from every component → centralized in `root.hcl`
- `provider {}` blocks removed from every component → centralized in `root.hcl`
- `terraform_remote_state` data sources → replaced by `dependency {}` blocks
- `variables.tf` + `.tfvars` → replaced by `inputs = {}` in `terragrunt.hcl`
- Common tags → defined once in `common.hcl`, merged everywhere via `include`

What stays the same:
- Same AVM modules, same versions, same inputs
- Same Azure resources created
- Same state files in the same storage account

---

## Integration architecture

### Dependency flow

```
state-backend ──► identity ──► networking ──► acr ──► aks ──► helm releases
     │                │                              │
     │                └── OIDC federation ───────────┘
     └── state storage for all components
```

Build order is strict: state backend must exist before anything else, identity
before OIDC federation, networking before AKS (cluster needs subnets), ACR
before Helm (images need a registry).

### Cross-project data flow

Project 2 outputs consumed by Project 1:

| Output | Source component | Consumer |
|--------|-----------------|----------|
| `aks_cluster_name` | aks | Helm deploy workflow (kubeconfig generation) |
| `aks_resource_group` | aks | Helm deploy workflow |
| `acr_login_server` | acr | Docker push workflow, Helm image references |
| `managed_identity_client_id` | identity | Workload Identity annotation on pods |
| `vnet_id` | networking | Reference only (not directly consumed) |

---

## CI/CD pipeline design

### Authentication

All workflows authenticate via GitHub OIDC → Azure Service Principal federated
credential. See [ADR-0003](adr/0003-github-oidc-over-long-lived-credentials.md).

Non-secret values stored as GitHub Actions variables:
- `AZURE_CLIENT_ID` — Service Principal application (client) ID
- `AZURE_TENANT_ID` — Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` — Target subscription ID

### Workflow architecture

```
PR opened/updated:
├── terraform-validate.yml     → fmt check, validate, tflint
├── terraform-plan.yml         → plan output posted as PR comment
└── helm-lint.yml              → helm lint + kubeconform validation

Push to main:
├── terraform-apply.yml        → apply infrastructure changes
├── docker-build.yml           → build + push images to ACR
└── helm-deploy.yml            → deploy/upgrade Helm releases on AKS

Manual/scheduled:
└── terraform-destroy.yml      → tear down all resources (cost control)
```

### Pipeline ordering

`terraform-apply` must complete before `helm-deploy` can run (infrastructure
must exist before applications deploy). Enforced via `workflow_run` trigger:

```yaml
on:
  workflow_run:
    workflows: ["Terraform Apply"]
    types: [completed]
```

---

## Observability strategy

Observability is integrated into Project 1, not a separate project.

### Stack

| Component | Tool | Deployment method |
|-----------|------|-------------------|
| Metrics collection | Prometheus | kube-prometheus-stack Helm chart |
| Dashboards | Grafana | kube-prometheus-stack Helm chart |
| Alerting | Alertmanager | kube-prometheus-stack Helm chart |
| Log tailing (debug) | stern (CLI) | Installed on workstation |

### Metrics collected

| Layer | Metrics | Source |
|-------|---------|--------|
| Infrastructure | Node CPU, memory, disk, network | node-exporter (via kube-prometheus-stack) |
| Kubernetes | Pod count, restart count, HPA status | kube-state-metrics (via kube-prometheus-stack) |
| Application | Request rate, latency, error rate (where exposed) | Online Boutique service /metrics endpoints |

### Dashboards (planned)

1. **Cluster overview** — Node health, pod distribution, resource utilization
2. **Application overview** — Per-service request rate, latency percentiles, error rate
3. **HPA dashboard** — Current vs desired replicas, scaling events over time
4. **Cost dashboard** — Node count over time, resource utilization efficiency

### Alerting rules (planned)

| Alert | Condition | Severity |
|-------|-----------|----------|
| High pod restart rate | > 3 restarts in 15 minutes | Warning |
| Node not ready | Node condition NotReady > 5 minutes | Critical |
| HPA at max replicas | Current = max for > 10 minutes | Warning |
| High error rate | 5xx rate > 5% of total requests for 5 minutes | Critical |
| Persistent volume near full | PV usage > 85% | Warning |

---

## Security model

### Identity and authentication

| Boundary | Method |
|----------|--------|
| CI/CD → Azure | GitHub OIDC federation (no stored secrets) |
| Pods → Azure services | Workload Identity (federated Managed Identity) |
| Developer → AKS | Azure AD integration (az aks get-credentials) |
| Developer → GitHub | SSH key authentication (signed commits) |

### Network security

- AKS network plugin: Azure CNI (required for Network Policies)
- Network policy engine: Calico (namespace-level pod traffic isolation)
- No public API server by default (optional: authorized IP ranges)
- ACR: private endpoint as stretch goal; initially public with admin disabled

### Supply chain

- Signed git commits (SSH signing, configured from first commit)
- AVM modules pinned to specific versions (reproducible builds)
- Helm chart versions pinned in Chart.yaml
- Container images tagged by SHA (not `latest`)
- Trivy scanning in CI pipeline (container vulnerability detection)

---

## Cost management

### Per-session cost estimate

| Resource | Cost/hour | Notes |
|----------|-----------|-------|
| AKS system pool (1x D2s_v3) | ~€0.10 | Always running during session |
| AKS user pool (1x D4s_v3) | ~€0.20 | Minimum 1, scales to 3 |
| ACR (Basic tier) | ~€0.15/day | Minimal during session |
| Azure Storage (state) | <€0.01 | Negligible |
| VNet, NSG, Identity | €0.00 | No hourly cost |
| **Total (minimum)** | **~€0.30/hr** | **1 system + 1 user node** |
| **Total (scaled)** | **~€0.70/hr** | **1 system + 3 user nodes** |

### Cost controls

- All resources destroyed at end of each session (`terraform destroy` / `terragrunt destroy-all`)
- Destroy workflow available as manual trigger in GitHub Actions
- No persistent data (state backend is the only long-lived resource, cost < €0.01/month)
- User pool autoscaling starts at 1 node (not 3)
- Basic tier ACR (not Standard/Premium)
- Single NAT gateway not used (AKS managed outbound)

---

## Timeline and phases

~20 weeks, ~6-9 hours/week (~140 total hours). Interview-ready material by week 10.

### Phase 1: Azure Landing Zone (weeks 1-4, ~35 hours)

- Azure Storage state backend (bootstrap)
- Managed Identity + GitHub OIDC federation
- VNet + subnets + NSGs
- ACR (Basic tier)
- AKS cluster (system + user pools)
- GitHub Actions: terraform-validate, terraform-plan, terraform-apply

**Deliverable:** Working AKS cluster deployable from CI/CD, all via Terraform + AVM.

### Phase 2: Helm charts + application deployment (weeks 5-8, ~30 hours)

- Helm umbrella chart structure
- Subcharts for all 11 Online Boutique services
- Resource requests/limits, probes, HPA, PDB per service
- Network Policies
- GitHub Actions: helm-lint, docker-build, helm-deploy

**Deliverable:** Online Boutique running on AKS, deployed via Helm from CI/CD.

### Phase 3: Observability (weeks 9-10, ~15 hours)

- kube-prometheus-stack deployment (Prometheus + Grafana + Alertmanager)
- Cluster overview + application dashboards
- Alerting rules
- Dashboard-as-code (JSON export in Git)

**Deliverable:** Full monitoring stack with dashboards and alerting. Portfolio is
interview-ready at this point.

### Phase 4: Terragrunt refactor (weeks 11-15, ~30 hours)

- Refactor iteration 1 (Terraform) to iteration 2 (Terragrunt)
- root.hcl, common.hcl, per-component terragrunt.hcl
- dependency blocks replacing terraform_remote_state
- Side-by-side comparison documentation

**Deliverable:** Same infrastructure, DRY. The diff between iterations is the artifact.

### Phase 5: Polish and stretch goals (weeks 16-20, ~30 hours)

- README polish and documentation completeness
- Karpenter on AKS (if available/stable)
- Sealed Secrets or External Secrets Operator
- Cost optimization analysis document
- Multi-environment (dev + staging) as stretch goal

**Deliverable:** Complete, polished portfolio.

---

## Interview talking points

### "Walk me through the architecture"

Start with the layered diagram: Project 2 builds the Azure foundation (VNet, AKS,
ACR, identity), Project 1 deploys applications onto it (Helm, CI/CD, observability).
Emphasize the integration is by design — `terraform_remote_state` / `dependency`
blocks connect the layers, not manual configuration.

### "Why AVM modules instead of writing your own?"

Point to ADR-0001. Production teams use battle-tested modules maintained by the
cloud provider community. Writing custom modules for VNet or AKS would duplicate
work that Microsoft engineers have already done, tested, and maintain. The value
is in composition and configuration, not in reinventing resource creation.

### "Why two Terraform iterations?"

Point to ADR-0005. Teams don't start with Terragrunt — they migrate to it when
plain Terraform's repetition becomes a maintenance burden. The side-by-side
comparison shows understanding of the *why*, not just the *how*. Specifically:
backend blocks centralized, provider blocks centralized, remote state replaced
by dependency blocks, variables replaced by inputs.

### "How do you handle secrets in CI/CD?"

GitHub OIDC federation — no secrets stored at all. The workflow requests a
short-lived token from GitHub's OIDC provider, presents it to Azure AD, and
receives a temporary access token. Point to ADR-0003 for the full trade-off
analysis.

### "What would you do differently at production scale?"

- Multi-account/subscription topology (hub-spoke or landing zone accelerator)
- Private AKS cluster with private endpoint for API server
- Premium ACR with geo-replication
- Azure Key Vault for secrets management (External Secrets Operator)
- Azure Monitor / Azure Managed Grafana instead of self-hosted
- GitOps with Flux/ArgoCD instead of push-based Helm deploy
- Multiple environments (dev/staging/prod) with promotion gates
