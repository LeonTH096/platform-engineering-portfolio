# ADR-0004: Use umbrella Helm chart with subcharts

## Status

Accepted

## Date

2026-05-02

## Context

Google Online Boutique consists of 11 microservices. Packaging them for Kubernetes
deployment via Helm can follow several patterns:

1. **Single monolithic chart** — One chart with all 11 services as templates.
   Simple but doesn't reflect how teams own and release services independently.

2. **Separate charts per service** — Each service is a standalone Helm chart in
   its own directory (or repo). Maximum independence but complex to deploy and
   version as a unit.

3. **Umbrella chart with subcharts** — A parent chart (`online-boutique`) that
   declares each service as a subchart dependency. Services can be individually
   versioned, enabled/disabled, and configured via the parent's `values.yaml`.

## Decision

Use an umbrella Helm chart with subcharts (option 3).

Structure:
```
helm/online-boutique/
├── Chart.yaml              # Declares subchart dependencies
├── values.yaml             # Global values + per-subchart overrides
├── charts/
│   ├── frontend/
│   ├── cartservice/
│   ├── productcatalogservice/
│   ├── currencyservice/
│   ├── paymentservice/
│   ├── shippingservice/
│   ├── emailservice/
│   ├── checkoutservice/
│   ├── recommendationservice/
│   ├── adservice/
│   └── redis/
└── templates/
    └── _helpers.tpl         # Shared template helpers
```

## Consequences

### Positive

- Mirrors real multi-team ownership: each subchart could be owned by a different team
- `helm dependency update` pulls all subcharts; `helm install` deploys everything
- Individual services can be disabled (`frontend.enabled: false`) for testing
- Per-environment values files override subchart defaults cleanly
- Portfolio artifact: demonstrates Helm composition patterns at scale (11 services)

### Negative

- More boilerplate than a monolithic chart (11 Chart.yaml files instead of 1)
- Subchart versioning adds maintenance overhead
- `helm dependency build` step required before install/upgrade

### Neutral

- Online Boutique already publishes Kubernetes manifests; our Helm charts wrap
  those manifests with templating, not rewrite them
- Subcharts share common labels/annotations via the `_helpers.tpl` in the parent

## References

- [Helm subcharts and globals](https://helm.sh/docs/chart_template_guide/subcharts_and_global_values/)
- [Online Boutique source](https://github.com/GoogleCloudPlatform/microservices-demo)
