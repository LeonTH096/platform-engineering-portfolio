# Project 1 — Platform Microservices

Deploys [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo)
(11-service microservices demo) on AKS using Helm, with GitHub Actions CI/CD
and Prometheus/Grafana observability.

## Why Online Boutique?

This is a **platform engineering** portfolio, not an application development portfolio.
Using a well-known, pre-built demo application lets the infrastructure work speak for itself:
Helm chart design, CI/CD pipelines, observability integration, and production-grade
Kubernetes patterns — without distraction from application code.

See [ADR-0006](../docs/adr/0006-online-boutique-as-demo-application.md) for the full rationale.

## Structure

```
project-1-platform-microservices/
├── helm/
│   └── online-boutique/       # Umbrella Helm chart
│       ├── charts/            # Subcharts (one per microservice)
│       ├── templates/         # Shared templates
│       ├── Chart.yaml
│       └── values.yaml
├── kubernetes/                # Raw manifests (if needed outside Helm)
└── docs/                      # Project-specific documentation
```

## Key decisions

- [ADR-0002: Managed node pools over Virtual Nodes](../docs/adr/0002-managed-node-pools-over-virtual-nodes.md)
- [ADR-0004: Umbrella Helm chart with subcharts](../docs/adr/0004-umbrella-helm-chart-with-subcharts.md)
- [ADR-0006: Online Boutique as demo application](../docs/adr/0006-online-boutique-as-demo-application.md)

## Status

🔲 Not started — pending Project 2 (cloud infrastructure) foundation
