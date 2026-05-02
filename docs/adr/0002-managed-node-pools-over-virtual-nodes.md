# ADR-0002: Use managed node pools over Virtual Nodes (ACI)

## Status

Accepted

## Date

2026-05-02

## Context

AKS offers two primary compute models for running workloads:

1. **Managed node pools** — Azure-managed VMs (VMSS-backed) that run kubelet and
   join the cluster as real nodes. You manage node count, VM size, scaling policies,
   OS patching cadence, and node-level operations.

2. **Virtual Nodes** (backed by Azure Container Instances) — serverless compute where
   pods run without dedicated VMs. Azure manages all infrastructure; you pay per
   pod-second with no idle cost.

Virtual Nodes reduce operational overhead and cost for bursty workloads. However,
this is a **platform engineering portfolio** — the goal is to demonstrate node-level
operational competency, not minimize it.

## Decision

Use managed node pools with a system pool + user pool topology:

- **System pool:** 1-2 nodes (Standard_D2s_v3), runs cluster-critical workloads
  (CoreDNS, kube-proxy, metrics-server). Tainted with `CriticalAddonsOnly=true:NoSchedule`.
- **User pool:** 1-3 nodes (Standard_D4s_v3), runs application workloads
  (Online Boutique services, Prometheus, Grafana). Autoscaling enabled.

## Consequences

### Positive

- Demonstrates node-level operations: scaling, taints, tolerations, node selectors
- Enables Cluster Autoscaler demonstration (a key portfolio artifact)
- Shows understanding of system vs user pool separation (AKS best practice)
- Allows demonstrating PodDisruptionBudgets during node scale-down
- Real-world pattern: most production AKS clusters use managed node pools

### Negative

- Higher idle cost than Virtual Nodes (mitigated: resources destroyed each session)
- Requires managing node pool sizing, OS upgrades, and scaling configuration
- System pool must always have at least one node running

### Neutral

- Karpenter on AKS is a stretch goal; managed node pools don't prevent future migration

## References

- [AKS node pool documentation](https://learn.microsoft.com/en-us/azure/aks/use-multiple-node-pools)
- [AKS best practices — cluster isolation](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-isolation)
- [Virtual Nodes overview](https://learn.microsoft.com/en-us/azure/aks/virtual-nodes)
