# ADR-0006: Use Google Online Boutique as the demo application

## Status

Accepted

## Date

2026-05-02

## Context

The portfolio needs a multi-service application to deploy on Kubernetes. Three
options were evaluated:

1. **Build a custom application** — Write a bespoke microservices app (e.g.,
   Node.js API + React frontend + PostgreSQL). Full control but shifts focus
   from infrastructure to application development.

2. **Use a minimal demo app** — Deploy a 2-3 service "hello world" architecture.
   Fast to set up but doesn't exercise real-world Kubernetes patterns (service
   mesh, inter-service communication, mixed workload types).

3. **Use Google Online Boutique** — An 11-service polyglot microservices demo
   (Go, Python, Java, C#, Node.js) with realistic inter-service communication,
   a gRPC-based service mesh, Redis state, and a web frontend.

## Decision

Use Google Online Boutique (option 3) as the demo application.

This is a **platform engineering** portfolio targeting a Platform Engineer role.
The application is deliberately not the candidate's work — the infrastructure
wrapping it is. Using a well-known, Google-maintained demo app:

- Eliminates "is the app itself any good?" as a review concern
- Provides 11 real services to exercise Helm subchart patterns, HPA, PDB, and
  network policies at realistic scale
- Includes a polyglot stack (Go, Python, Java, C#, Node.js) that tests container
  build pipelines across languages
- Is immediately recognizable to interviewers who have used it themselves

## Consequences

### Positive

- 100% infrastructure focus: no time spent writing application code
- 11 services = realistic Kubernetes complexity (not a toy deployment)
- Well-documented, stable, actively maintained by Google
- Pre-existing Prometheus metrics in several services
- gRPC inter-service communication exercises network policy design
- Interviewers may already know Online Boutique, reducing explanation overhead

### Negative

- No opportunity to demonstrate application-level skills (trade-off accepted:
  this is a platform role, not a developer role)
- Upstream changes to Online Boutique may require Helm chart updates
- Some services have specific resource requirements (Redis needs persistence)

### Neutral

- Container images are pre-built by Google; our CI/CD can optionally rebuild
  them from source to demonstrate the full build pipeline, or use Google's
  published images to save time

## References

- [Online Boutique GitHub](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Online Boutique architecture](https://github.com/GoogleCloudPlatform/microservices-demo#architecture)
